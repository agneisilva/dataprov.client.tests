% --------------- G1-GoAmazon 2014 --------------------------------------
% go amazon g1 data process
% creates a data base from gps, cpc, co, o3, ... datasets
% written by Luciana Rizzo - nov/2015
%
% basedados
% 1 - flight#
% 2 - gps time (utc)
% 3:5 - lat, long, alt
% 6 - co (ppmv)
% 7 - o3 (ppbv)
% 8:10 - no, no2, noy(ppbv)
% 11:15 - CPC3010 CPC3025 Flag IsokP_mbar IsokT_C
% 16:21 - Scat450 Scat550 Scat700 BScat450 BScat550 BScat700 (Mm-1)
% 22:24 - Abs461.6 Abs522.7 Abs648.3 (Mm-1) 
% 25:28 - Neph_Press(mb) Neph_Temp(oC) Neph_RH(%) CloudFlag
% 29:31 - Acetonitrile, Acetaldehyde, Isoprene
% 32:34 - MVK+MACR, monoterp81, monoterp137
% 35:37 - Benzene, Toluene, voc_flag
% 38:39 - co2, ch4 (ppmv)
% 40 - STP correction factor (1 atm, 20oC) for cpc (isokinetic inlet)
% 41 - Manaus plume flag (based on peaks on CO,CPC,Abs, avoing peaks of acetonitrile)
% 42 - Biomass burning plume flag
% 43 - Wind speed (m/s) - horizontal
pref=1013.25; %mbar
tref=293.15; %K
%
% List of flights (flight#,dep.time(utc)):
flights=[1 datenum(2014,2,22,14,37,11); ...
    2 datenum(2014,2,25,16,30,31); ...
    3 datenum(2014,3,1,13,33,9); ...
    4 datenum(2014,3,1,17,13,59); ...
    5 datenum(2014,3,3,17,46,34); ...
    6 datenum(2014,3,7,13,8,11); ...
    7 datenum(2014,3,10,14,22,37); ...
    8 datenum(2014,3,11,14,39,59); ...
    9 datenum(2014,3,12,17,20,25); ...
    10 datenum(2014,3,13,14,14,14); ...
    11 datenum(2014,3,14,14,17,7); ...
    12 datenum(2014,3,16,14,38,18); ...
    13 datenum(2014,3,17,16,23,11); ...
    14 datenum(2014,3,19,14,25,33); ...
    15 datenum(2014,3,21,16,32,34); ...
    16 datenum(2014,3,23,14,56,47); ...
    17 datenum(2014,9,6,16,16,7); ...
    18 datenum(2014,9,9,15,1,14); ...
    19 datenum(2014,9,11,14,32,40); ...
    20 datenum(2014,9,12,14,41,26); ...
    21 datenum(2014,9,13,14,50,5); ...
    22 datenum(2014,9,15,14,59,6); ...
    23 datenum(2014,9,16,15,40,15); ...
    24 datenum(2014,9,18,14,35,59); ...
    25 datenum(2014,9,19,14,30,23); ...
    26 datenum(2014,9,21,15,17,32); ...
    27 datenum(2014,9,22,14,23,40); ...
    28 datenum(2014,9,23,15,46,45); ...
    29 datenum(2014,9,25,17,09,24); ...
    30 datenum(2014,9,27,18,29,21); ...
    31 datenum(2014,9,28,15,9,12); ...
    32 datenum(2014,9,30,14,55,10); ...
    33 datenum(2014,10,1,14,39,1); ...
    34 datenum(2014,10,3,14,50,51); ...
    35 datenum(2014,10,4,16,24,46)];    
%
% GoAmazon-G1 flights with legs out of the Manaus plume (flight start time):
% 07-Mar-2014 13:08:11 (6)
% 12-Sep-2014 14:41:26 (20)
% 27-Sep-2014 18:29:21 (30)
% 01-Oct-2014 14:39:01 (33)
% 03-Oct-2014 14:50:51 (34)
%
readfromraw=true;
%
% @ Read and append data files ------------------------------------
if(~readfromraw)
    gps=load('C:\A\GOAMAZON\G1\gps_G1.mat');
    co=load('C:\A\GOAMAZON\G1\co_G1.mat');
    o3=load('C:\A\GOAMAZON\G1\o3_G1.mat');
    nox=load('C:\A\GOAMAZON\G1\nox_G1.mat');
    cpc=load('C:\A\GOAMAZON\G1\cpc_G1.mat');   
    scatabs=load('C:\A\GOAMAZON\G1\scatabs_G1.mat'); 
    voc=load('C:\A\GOAMAZON\G1\voc_G1.mat');
    co2=load('C:\A\GOAMAZON\G1\co2_G1.mat');
    basedados=load('C:\A\GOAMAZON\G1\database_G1.mat');
else
    % gps (flight# time(utc) lat long alt windspeed(m/s))
    caminho='C:\A\GOAMAZON\G1\mei-iwg1\';
    files=dir(caminho);
    gps=zeros(1,6);
    for ifile=6:size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        C=importdata(strcat(caminho,nome));
        data(:,2)=datenum(C.textdata(3:length(C.textdata),2),'yyyy-mm-dd HH:MM:SS'); %
        data(:,1)=ifile-5; % flight number
        data(:,3:5)=C.data(:,1:3); %lat, long, alt
        data(:,6)=C.data(:,25); % windspeed(m/s) - Defined in the earth frame at altitude Zg.
        gps=cat(1,gps,data);
        clear data C
    end
    gps(1,:)=[];
    save('C:\A\GOAMAZON\G1\gps_G1.mat','gps','-mat')
    %
    % co (flight# time(utc) co(ppmv) n2o(ppmv) h2o(ppmv))
    caminho='C:\A\GOAMAZON\G1\CO\data\';
    files=dir(caminho);
    co=zeros(1,5);
    for ifile=3:size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        fid=fopen(strcat(caminho,nome));
        textscan(fid,'%s',152);
        pular=true;
        while(pular)
            aux=textscan(fid,'%s',1);
            if(strcmp(aux{1,1}(1),'ppmv')==1)
                pular=false;
            end
        end
        textscan(fid,'%s',2);
        C=textscan(fid,'%s%s%f%f%f');
        fclose(fid);
        data(:,2)=datenum(strcat(C{1,1},C{1,2}),'yyyy-mm-ddHH:MM:SS'); %
        data(:,1)=ifile-2; % flight number
        data(:,3)=C{1,3}; %co,n2o,h2o (ppmv)
        data(:,4)=C{1,4};
        data(:,5)=C{1,5};
        co=cat(1,co,data);
        clear data C
    end
    co(1,:)=[];
    % corrigindo número dos voos que estão fora de ordem
    aux=find(diff(co(:,2))<0);
    co=cat(1,co(aux+1:length(co),:),co);
    aux=find(diff(co(:,2))<0);
    co(aux+1:length(co),:)=[];
    co(co(:,1)==29,1)=1;
    co(co(:,1)==30,1)=2;
    co(co(:,1)==31,1)=3;
    co(co(:,1)==32,1)=4;
    co(co(:,1)==33,1)=5;
    aux=find(diff(co(:,1))<0);
    co(aux+1:length(co),1)=co(aux+1:length(co),1)+5;    
    save('C:\A\GOAMAZON\G1\co_G1.mat','co','-mat')
    %
    % o3 (flight# time(utc) o3(ppbv))
    caminho='C:\A\GOAMAZON\G1\ozone\data\';
    files=dir(caminho);
    o3=zeros(1,3);
    for ifile=3:size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        fid=fopen(strcat(caminho,nome));
        aux=textscan(fid,'%s',74);
        pular=true;
        while(pular)
            aux=textscan(fid,'%s',1);
            if(strcmp(aux{1,1}(1),'ppbv')==1)
                pular=false;
            end
        end
        C=textscan(fid,'%s%s%f');
        fclose(fid);
        data(:,2)=datenum(strcat(C{1,1},C{1,2}),'yyyy-mm-ddHH:MM:SS'); %
        data(:,1)=ifile-2; % flight number
        data(:,3)=C{1,3}; %o3 (ppbv)
        o3=cat(1,o3,data);
        clear data C
    end
    o3(1,:)=[];
    save('C:\A\GOAMAZON\G1\o3_G1.mat','o3','-mat')
    %
    % nox (flight# time(utc) no no2 noy(ppbv))
    % Precision: 2 sigma ~10 pptv @~15s; ~30 pptv @15s; ~50 pptv @15s
    caminho='C:\A\GOAMAZON\G1\NOx\data\';
    files=dir(caminho);
    nox=zeros(1,5);
    for ifile=3:size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        fid=fopen(strcat(caminho,nome));
        aux=textscan(fid,'%s',195);
        pular=true;
        while(pular)
            aux=textscan(fid,'%s',1);
            if(strcmp(aux{1,1}(1),'ppbv')==1)
                pular=false;
            end
        end
        textscan(fid,'%s',2);
        C=textscan(fid,'%s%s%f%f%f');
        fclose(fid);
        data(:,2)=datenum(strcat(C{1,1},C{1,2}),'yyyy-mm-ddHH:MM:SS'); %
        data(:,1)=ifile-2; % flight number
        data(:,3)=C{1,3}; %no,no2,noy (ppbv)
        data(:,4)=C{1,4};
        data(:,5)=C{1,5};
        nox=cat(1,nox,data);
        clear data C
    end
    nox(1,:)=[];
    % corrigindo número dos voos (não houve medidas no voo 17)
    aux=find(nox(:,2)>=datenum(2014,9,9));
    nox(aux(1):length(nox),1)=nox(aux(1):length(nox),1)+1;    
    save('C:\A\GOAMAZON\G1\nox_G1.mat','nox','-mat')
    %
    % cpc (flight# time(utc) CPC3010 CPC3025 Flag IsokP_mbar IsokT_C)
    % All corrections applied (level R2); no STP compensation
    % UNCERTAINTY:less than 10%
    % Flag=0: good; 
    % Flag=1: questionable (10%>Aerosol flow fluctuation>5% and/or Sampling inside of clouds); 
    % Flag=2: bad (Aerosol flow fluctuation >10% and/or Saturator or Condenser temperature fluctuation >±0.5°C)
    caminho='C:\A\GOAMAZON\G1\mei-cpc\';
    files=dir(caminho);
    cpc=zeros(1,7);
    for ifile=3:37%size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        fid=fopen(strcat(caminho,nome));        
        textscan(fid,'%s',11); % skipping
        dia=textscan(fid,'%f,%f,%f',1);
        textscan(fid,'%s',217); % skipping
        pular=true;
        while(pular)
            aux=textscan(fid,'%s',1);
            if(strcmp(aux{1,1}(1),'Start_UTC,')==1)
                pular=false;
            end
        end
        textscan(fid,'%s',1);        
        C=textscan(fid,'%f%f%f%f%f%f','Delimiter',',');
        fclose(fid);
        % C{1,1}: UTC time in second to the start (YYMMDD 00:00:00) of the day. Synchronized daily with GPS signal.
        data(:,2)=datenum(dia{1,1:3})+C{1,1}/60/60/24; %
        data(:,1)=ifile-2; % flight number
        for j=2:6
            data(:,j+1)=C{1,j}; %CPC3010(cm-3) CPC3025(cm-3) Flag(0,1,2) IsokP_mbar IsokT_C
        end            
        cpc=cat(1,cpc,data);
        clear data C dia
    end
    cpc(1,:)=[];
    save('C:\A\GOAMAZON\G1\cpc_G1.mat','cpc','-mat')   
    %
    % scatabs (flight# time(utc) Scat450 Scat550 Scat700 BScat450 BScat550 BScat700 Abs461.6 Abs522.7 Abs648.3(Mm-1) Press(mb) Temp(oC) RH(%) CloudFlag)
    % No STP compensation?
    % 1 - Time: Time in UT (decimal)
    % 2:4 - hh,mm,ss (all Time in UT)
    % 5:7 - tbs_tr_corr: Corrected total scattering coeff at 450,550,700nm (Mm^-1)
    % 8:10 - bbs_corr: Corrected back scattering coeff at 450,550,700nm  (Mm^-1)
    % 11:13 - tba_corr:	Corrected absorption coeff at 461.6,522.7,648.3 nm (Mm^-1)
    % 14 - neph_P: Pressure in Nephelometer (mb)
    % 15 - neph_T: Temperature in Nephelometer (oC)
    % 16 - neph_R: Relative Humidity in Nephelometer (%)
    % 17 - Cld_F: Cloud Flags (0 cloud free sampling)
    caminho='C:\A\GOAMAZON\G1\chand-psap\';
    files=dir(caminho);
    scatabs=zeros(1,15);
    for ifile=3:37%size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        C=importdata([caminho,nome]);        
        dia=datenum(nome(21:28),'yyyymmdd');
        data(:,2)=dia+C(:,1)/24; %
        data(:,1)=ifile-2; % flight number
        data(:,3:15)=C(:,5:17);                  
        scatabs=cat(1,scatabs,data);
        clear data C dia
    end
    scatabs(1,:)=[];
    save('C:\A\GOAMAZON\G1\scatabs_G1.mat','scatabs','-mat')    
    %
    % ptrms (selected m/z ratios) --> está em hora local de Manaus
    % Chato de processar, porque as colunas de dados são diferentes de
    % um arquivo para o outro. Então selecionei algumas espécies mais importantes (do meu ponto de vista)
    % 1 - flight#
    % 2 - date (utc)
    % 3 - m/z 42 Acetonitrile
    % 4 - m/z 45 Acetaldehyde
    % 5 - m/z 69a+69b+69c Isoprene
    % 6 - m/z 71 MVK+MACR
    % 7:8 - m/z 81 e 137 Monoterpenes
    % 9 - m/z 79 Benzene
    % 10 - m/z 93 Toluene
    % 11 - Flag: 0 (normal operation), 1 (zero period), 2 (bad data), 3 (quanlitative analysis only) 
    caminho='C:\A\GOAMAZON\G1\shilling-ptrms\';
    files=dir(caminho);
    voc=zeros(1,11);
    for ifile=8:41%size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        C=importdata([caminho,nome]);   
        data=nan(length(C.data),11);
        data(:,1)=ifile-7; % flight number
        for i=2:length(C.textdata)
            data(i-1,2)=datenum(C.textdata(i,1),'m/dd/yyyy HH:MM:SS')+4/24; % conversao para utc
        end1;
        end
        if(achou)
            data(:,3)=C.data(:,j-2); % acetonitrile
        end
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz45');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,4)=C.data(:,j-2); % acetaldehyde
        end
        aux=strfind(C.textdata(1,:),'mz69');
        isop=[]; iisop=1;
        for j=2:size(C.textdata,2)
            if(~isempty(aux{1,j}))
                isop(iisop)=j;
            end
        end        
        if(~isempty(isop))
            data(:,5)=sum(C.data(:,isop-1),2); % isoprene
        end
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz71');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,6)=C.data(:,j-2); % MVK+MACR
        end    
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz81');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,7)=C.data(:,j-2); % Monoterpenes
        end  
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz137');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,8)=C.data(:,j-2); % Monoterpenes
        end     
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz79');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,9)=C.data(:,j-2); % Benzene
        end      
        j=2; achou=false;
        while (j<=size(C.textdata,2) && ~achou)            
            aux=strcmp(C.textdata(1,j),'mz93');
            if(aux==1); achou=true; end    
            j=j+1;
        end
        if(achou)
            data(:,10)=C.data(:,j-2); % Toluene
        end    
        data(:,11)=C.data(:,size(C.data,2));                
        voc=cat(1,voc,data);
        clear data C 
    end
    voc(1,:)=[];
     % corrigindo número dos voos (não houve medidas no voo 17)
    aux=find(voc(:,2)>=datenum(2014,9,9));
    voc(aux(1):length(voc),1)=voc(aux(1):length(voc),1)+1;  
    save('C:\A\GOAMAZON\G1\voc_G1.mat','voc','-mat')    
    %
    % co2 
    % 1-sigma precision is < 100ppb for CO2 and < 0.7ppb for CH4
    % Estimated accuracy is 2ppm for CO2, and 5ppb for CH4
    % 1 - flight#
    % 2 - date (utc)
    % 3 - pressure
    % 4 - h2o(%)
    % 5 - co2 (ppm)
    % 6 - ch4 (ppm)
    caminho='C:\A\GOAMAZON\G1\dubey-gasconcs\';
    files=dir(caminho);
    co2=zeros(1,6);
    for ifile=3:36%size(files,1)
        nome=getfield(files, {ifile,1}, 'name');
        disp(nome)
        C=importdata([caminho,nome]);   
        data=nan(length(C.data),6);
        data(:,1)=ifile-2; % flight number
        aux=strcat(C.textdata(3:length(C.textdata),1),C.textdata(3:length(C.textdata),2));
        data(:,2)=datenum(aux(:,1),'m/dd/yyyyHH:MM:SS');
        data(:,3:6)=C.data(:,1:4);
        co2=cat(1,co2,data);
        clear data C 
    end
    co2(1,:)=[];
     % corrigindo número dos voos (não houve medidas no voo 3)
    aux=find(co2(:,2)<=datenum(2014,2,28));
    co2(aux(length(aux))+1:length(co2),1)=co2(aux(length(aux))+1:length(co2),1)+1;  
    save('C:\A\GOAMAZON\G1\co2_G1.mat','co2','-mat')       
end
%
% @ Concatenate data files into a single data base ------------------------
% 1 - flight#
% 2 - gps time (utc)
% 3:5 - lat, long, alt
% 6 - co (ppmv)
% 7 - o3 (ppbv)
% 8:10 - no, no2, noy(ppbv)
% 11:15 - CPC3010 CPC3025 Flag IsokP_mbar IsokT_C
% 16:21 - Scat450 Scat550 Scat700 BScat450 BScat550 BScat700 (Mm-1)
% 22:24 - Abs461.6 Abs522.7 Abs648.3 (Mm-1) 
% 25:28 - Neph_Press(mb) Neph_Temp(oC) Neph_RH(%) CloudFlag
% 29:31 - Acetonitrile, Acetaldehyde, Isoprene
% 32:34 - MVK+MACR, monoterp81, monoterp137
% 35:37 - Benzene, Toluene, voc_flag
% 38:39 - co2, ch4 (ppmv)
% 40 - STP correction factor
% 41 - Manaus plume flag (based on peaks on CO,CPC,Abs, avoing peaks of acetonitrile)
% 42 - Biomass burning plume flag
% 43 - Wind speed (m/s) - horizontal
%
basedados=gps;
basedados(:,6:43)=nan(length(basedados),length(6:43));
basedados(:,43)=gps(:,6);
for i=1:length(basedados)
    if(mod(i,100)==0)
        disp(i)
    end
    % co (tolerância de 0.4 seg)
    aux=find(co(:,2)>basedados(i,2)-0.4/60/60/24 & co(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,6)=co(aux,3);
    elseif(length(aux)>1)
        disp('co')
        disp(i)
    end
    % o3 (tolerância de 0.4 seg)
    aux=find(o3(:,2)>basedados(i,2)-0.4/60/60/24 & o3(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,7)=o3(aux,3);
    elseif(length(aux)>1)
        disp('o3')
        disp(i)
    end
    % nox (tolerância de 0.4 seg)
    aux=find(nox(:,2)>basedados(i,2)-0.4/60/60/24 & nox(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,8:10)=nox(aux,3:5);
    elseif(length(aux)>1)
        disp('nox')
        disp(i)
    end
    % cpc (tolerância de 0.4 seg)
    aux=find(cpc(:,2)>basedados(i,2)-0.4/60/60/24 & cpc(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,11:15)=cpc(aux,3:7);
    elseif(length(aux)>1)
        disp('cpc')
        disp(i)
    end
    % scatabs (tolerância de 0.4 seg)
    aux=find(scatabs(:,2)>basedados(i,2)-0.4/60/60/24 & scatabs(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,16:28)=scatabs(aux,3:15);
    elseif(length(aux)>1)
        stop
    end
    % voc (tolerância de 0.4 seg)
    aux=find(voc(:,2)>basedados(i,2)-0.4/60/60/24 & voc(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,29:37)=voc(aux,3:11);
    elseif(length(aux)>1)
        disp('voc')
        disp(i)
    end
    % co2 (tolerância de 0.4 seg)
    aux=find(co2(:,2)>basedados(i,2)-0.4/60/60/24 & co2(:,2)<basedados(i,2)+0.4/60/60/24);
    if(length(aux)==1)
        basedados(i,38:39)=co2(aux,5:6);
    elseif(length(aux)>1)
        basedados(i,38:39)=co2(aux(1),5:6);
    end
end
basedados(:,40)=(pref*(basedados(:,15)+273.15))./(tref*basedados(:,14));
save('C:\A\GOAMAZON\G1\database_G1.mat','basedados','-mat')       
%
%
% Plots 3D trajetorias
basedados(basedados(:,5)<0,5)=NaN;
basedados(basedados(:,5)>5000,5)=NaN;
figure
for iflight=1:35
    aux=find(basedados(:,1)==iflight);
    plot3(basedados(aux,3),basedados(aux,4),basedados(aux,5),'k.'),grid on,hold on
    plot(-3.1,-60.017,'ro','MarkerFaceColor','r','MarkerSize',8) % Manaus
    plot(-3.213,-60.598,'go','MarkerFaceColor','g','MarkerSize',8) % T3
    xlabel('Lat'),ylabel('Long'),zlabel('Altitude (m)')
    title(['Flight #',num2str(iflight)])
    hgsave(gcf,['C:\A\GOAMAZON\G1\trajetorias_3D\flight',num2str(iflight)])
    saveas(gcf,['C:\A\GOAMAZON\G1\trajetorias_3D\flight',num2str(iflight)],'jpg')
    hold off
end