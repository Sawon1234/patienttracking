function varargout=getInterpolatedWaveforms(varLabels,category,tm,val,Ts,outVarName,show)
%
% waveforms= getInterpolatedWaveforms(varLabels,category)
%
% Generates interpolated waveforms from unevenly sampled data
% in category.
%
% varLabeLs Nx1 cell array of the physiological labels to category of the waveforms to be
% interpolated
%
% category Mx3 cell array
%
% Ts 1x1 sampling interval (in hours) from which to interpolate data
%
% outVarName Nx1 cell array for the names of the new interpolated data
%
% Output is multiple variables, one for each element of varLabels see
% example below:
%
% %Example 1:
% outVarName={'lact','map','hr','urine'};
%[lact,map,hr,urine]=getInterpolatedWaveforms(varLabels,category,Ts,outVarName);

NvarName=length(varLabels);

nb=round(0.5/Ts); %Filter waveforms with half an hour moving average
b=ones(nb,1)./nb;
for n=1:NvarName
    
    ind=strcmp(category,varLabels{n});
    x=[tm(ind) val(ind)];
    x=sortrows(x,1);
    del=find(isnan(x(:,1))==1);
    if~(isempty(del))
        x(del,:)=[];
    end
    isUrine=1; %Urine requires special attention.
    if(~strcmp(varLabels{n},'URINE'))
        %Remove cases where value is zero for all time series except urine
        del=find(x(:,2)==0);
        if(~isempty(del))
            error(['Time series has zeros values : ' varLabels{n}])
        end
        isUrine=0; %set flag for false, this is not urine series
    end
    [Nx,~]=size(x);
    
    if(Nx>1)
        %Average any points measue at the same time
        diff_tm=diff(x(:,1));
        ind_rep=find(diff_tm==0);
        if(~isempty(ind_rep))
            warning(['Found ' num2str(length(ind_rep)) ' repeated points in ' varLabels{n}])
            if(isUrine)
                %In urine case, sum the points together instead of
                %averaging
                for reps=1:length(ind_rep)
                    x(ind_rep+1,2)=x(ind_rep+1,2)+x(ind_rep,2);
                    x(ind_rep,2)=NaN;
                end
                %Remove the repeats
                del=find(isnan(x(:,2))==1);
                x(del,:)=[];
            else 
                %For other series, take the approximate average
                %(this will be biased towards the last sample)
                 for reps=1:length(ind_rep)
                    x(ind_rep+1,2)=mean(x(ind_rep+1,2)+x(ind_rep,2));
                    x(ind_rep,2)=NaN;
                end
                %Remove the repeats
                del=find(isnan(x(:,2))==1);
                x(del,:)=[];
            end
            
        end
        
        if(isUrine)
            %Do not apply median to urine, calculative cumulative hourly
            x=hourly_cumulative(x);
        else
            x=hourly_median(x);
        end
        
        %Interpolate waveforms
        y=[x(1,1):Ts:x(end,1)]';
        y(:,2)=interp1(x(:,1),x(:,2),y,'linear');
        [Ny,~]=size(y);
        if((Ny+1)> (length(b)*3))
            %Filter the waveforms through a moving average
            %filtfilt only works for cases where Ny is 3x filter order
            y(:,2)=filtfilt(b,1,y(:,2));
        end
    else
        if(Nx==1)
            %Case where there is only one value of x
            y=x;
        else
            %Nx=0
            y=[NaN NaN];
        end
    end
    
    %Set y to the time series being analyzed
    eval([outVarName{n} '=y;'])
    if(show)
        figure
        plot(x(:,1),x(:,2),'-o')
        hold on;grid on
        plot(y(:,1),y(:,2),'r')
        title(outVarName{n})
    end
end
for n=1:nargout
    eval(['varargout{n}=' outVarName{n} ';'])
end