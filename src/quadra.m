classdef quadra
    %QUADRA Functions for Eliko Quadra Impedance Spectroscopy system
    %   Detailed explanation goes here

    properties

    end

    methods(Static)
        function fileout = writetable(fname,protocol)
            %QUADRA Write Protocol to file for use in the Quadra software
            %   Inputs:
            %   fname  - requires .csv extension
            %   protocol - Nx4 array in [EX+ EX- V+ V-] order

            s=('INDEX,EX+,EX-,V+,V-\r\n');
            %write them to a file with header
            fid=fopen(fname,'w+');

            fprintf(fid,s);

            for iThing =1:size(protocol,1)
                fprintf(fid,'%d, %d, %d, %d, %d \r\n',iThing,protocol(iThing,1),protocol(iThing,2),protocol(iThing,3),protocol(iThing,4));
            end

            fclose(fid);


        end

        function [Data] = readdata(fname,plotflag)
            %ReadEliko Load data from Eliko Quadra MUX GUI v1.12
            %   Detailed explanation goes here

            % TODO
            % Handle when run header is missing
            % plot stuff
            % time is broken?

            fprintf('Loading Eliko File %s\n',fname);

            pfid=fopen([fname]);

            txt=textscan(pfid,'%s','Delimiter','\n');
            fclose(pfid);

            txt=txt{1};
            txt=cellstr(txt);

            %% read info from file


            hdrstr=txt(startsWith(txt,'Device'));
            info.status_text=hdrstr{1};
            info.fname=fname;

            datetxt=strsplit(hdrstr{1},'\t');
            datetxt=strsplit(datetxt{2},'(');
            datetxt=datetxt{1};

            info.datetxt=datetxt;


            datetxt_formatted=datestr(datenum(datetxt,'yyyy:mm:dd    HH:MM:SS'));


            % common format so use function
            info.excitation_level=readhdrline(txt,'Excitation');
            info.Vgain=readhdrline(txt,'Voltage Channel Gain');
            info.Igain=readhdrline(txt,'Current Channel Gain');
            info.Vrange=readhdrline(txt,'Voltmeter Range');
            info.Irange=readhdrline(txt,'Ampermeter Range');
            info.step_period_ms=readhdrline(txt,'Step Period');

            % measurement table has different layout
            tbltxt=txt(startsWith(txt,'Measurement Table'));
            tbltxt=strsplit(tbltxt{1},':');
            tbltxt=strsplit(tbltxt{2},'  ');
            info.measurement_table_name=strtrim(tbltxt{1});
            info.measurement_table_size=sscanf(tbltxt{2},'%g');

            Nchan=info.measurement_table_size;

            Nruns= length(txt(startsWith(txt,'run')));


            fprintf('File created at %s, Excitiation: %g Vgain:%g Vrange:%g Igain:%g Irange:%g\n',datetxt_formatted,info.excitation_level, info.Vgain, info.Vrange, info.Igain, info.Irange)
            fprintf('Measurement Table: %s, %d measurements %d repeats\n',info.measurement_table_name,Nchan,Nruns);

            %% read freqs
            freqtxt=txt(startsWith(txt,'Freq'));
            freqtxt=strsplit(freqtxt{1},'\t');
            freqtxt=freqtxt(2:end);

            if mod(size(freqtxt,2),2)
                error('number of freqs not equal')
            end

            Nfreq=size(freqtxt,2)/2;

            freq=zeros(size(freqtxt,2),1);

            for iFreq=1:size(freqtxt,2)
                freqtmp=sscanf(freqtxt{iFreq},'%g');
                if strcmp(freqtxt{iFreq}(end),'k')
                    freqtmp=freqtmp *1000;
                end
                freq(iFreq)=freqtmp;

            end

            if ~all(freq(1:Nfreq) == freq(Nfreq+1:end))
                error('freqs dont match on Re and Im side!');
            end

            freq=freq(1:Nfreq);
            %% read data

            runstarts=find(startsWith(txt,'run'));
            runstarts_num=find(startsWith(txt,'0.0'));

            if length(runstarts) ~= length(runstarts_num)
                fprintf(2,'SOME RUNS WERE NOT WRITTEN PROPERLY! THESE WILL BE SKIPPED\n');
            end



            I=nan(Nchan,Nruns);
            U=I;
            t=nan(Nruns,1);

            Vreal=nan(Nchan,Nfreq,Nruns);
            Vimag=Vreal;

            prevtime=datenum(datetxt,'yyyy:mm:dd    HH:MM:SS');
            prevmillis=strsplit(datetxt,'.');
            prevmillis=sscanf(prevmillis{2},'%g')/1000;

            for iRun=1:Nruns
                curstart=runstarts(iRun);

                if iRun==Nruns
                    curend=size(txt,1);
                else
                    curend=runstarts(iRun+1)-1;
                end

                runtxt=txt(curstart:curend);

                rundatexttmp=strsplit(runtxt{1},'\t');
                rundatetxt=rundatexttmp{3};

                curtime=datenum(rundatetxt,'yyyy:mm:dd    HH:MM:SS');
                curmillis=strsplit(rundatetxt,'.');
                curmillis=sscanf(curmillis{2},'%g')/1000;

                t(iRun)=(curtime + curmillis) - (prevtime + prevmillis);



                %first line (and others?) has header on top so find the data first
                rundatastart=find(startsWith(runtxt,'0.0'),1);

                datalength=size(runtxt,1) -rundatastart +1 ;

                % check if the amount of data is expected, either not wrriten or in
                % case where a run was missing
                if datalength ~= Nchan
                    if datalength > Nchan
                        datalength=Nchan;
                    else
                        error('datamissing');
                    end
                end


                %data contains line, Re Im and current
                datacur=zeros(datalength,Nfreq*2 +3);

                for iLine=1:datalength
                    datacur(iLine,:)=sscanf(runtxt{rundatastart+ iLine -1},'%g')';

                end

                if ~all(datacur(:,1)' == 0:Nchan-1)
                    error('data not in expecte format');
                end


                U(:,iRun)=datacur(:,end-1);
                I(:,iRun)=datacur(:,end);

                Vreal(:,:,iRun)=datacur(:,2:Nfreq+1);
                Vimag(:,:,iRun)=datacur(:,Nfreq+2:2*Nfreq+1);

            end
            %% plot

            %% store in struct

            Data.info=info;
            Data.t=t;
            Data.Vreal=Vreal;
            Data.Vimag=Vimag;
            Data.I=I;
            Data.U=U;
            Data.freq=freq;

            [filepath, filename]=fileparts(fname);
            if isempty(filepath)
                filepath=pwd;
            end
            save([filepath filesep filename '.mat'],'Data');
        end


    end

end
%% subfunctions
function val = readhdrline(t,valname)
    hdrstr=t(startsWith(t,valname));
    c=strsplit(hdrstr{1},':');
    val=sscanf(c{2},'%g');
end
