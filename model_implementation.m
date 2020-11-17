%Requirements: mat file from mobility_simulation.m
%This code implements the matematical model detailed in "A Softwarized and 
% MEC-Enabled Protocol Architecture Supporting Consumer Mobility in
% Information-Centric Networks" and plots the results
N=input('Number of nodes:'); %Enter the number of nodes in the network
L=input('Number of consumers:'); %Enter the number of consumers in the network
T_D_vect=[10^-1 10000]; %[s] Average time interval between the generation of two consecutive contents
T_D_vect=logspace(log10(min(T_D_vect)),log10(max(T_D_vect)),10);
speed_vect=[3 30]; %[km/h] Average consumer speed
rtt=0.1; %[s] Round Trip Time
k=4; %Average number of neighbors per node

load(sprintf('parameters-%d-%d',N,L),'A_l','d','D') %Get the number of stale disjoint links, the average shortest path and the number of active links
A=A_l+1; %Set the number of routers of the stale disjoint path
if L==1
    D=d; %Adjust the model in case of single mobile consumer
end

Hint=14; %[B] Header size of Interest packet
Hdat=37; %[B] Header size of Data packet
content_name=17.44; %[B] Average content name size
payload_size_vect=5*[10^3 10^5 10^7]; % [B] Payload size

match_field=4+4+content_name+4+4; %[B] Size of OpenFlow match field
OF_FM=8+38+match_field+0.56;%[B] Size of OpenFlow Modify Flow Entry message
OF_FR=8+16+match_field+4+2.56; %[B] Size of OpenFlow Flow Removed message
OF_PS=8+8; %[B] Size of OpenFlow Port Status message
OF_PI=8+12+match_field+2.56; %[B] Size of OpenFlow Packet IN message
HTTP_POST=900; %[B] Size of Subscription Request message

O_int=ones(length(T_D_vect),length(payload_size_vect));
O_dat=ones(length(T_D_vect),length(payload_size_vect));
O_tot=ones(length(T_D_vect),length(payload_size_vect));
ex_dat=ones(length(T_D_vect),length(payload_size_vect));

overhead_POF_NI=ones(length(T_D_vect),length(payload_size_vect));
overhead_POF_RI=ones(length(T_D_vect),length(payload_size_vect));
overhead_RPA=ones(length(T_D_vect),length(payload_size_vect));
overhead_OF_NI=ones(length(T_D_vect),length(payload_size_vect));
overhead_OF_RI=ones(length(T_D_vect),length(payload_size_vect));

data_plane_RPA=ones(length(T_D_vect),length(payload_size_vect));
data_plane_PPA=ones(length(T_D_vect),length(payload_size_vect));
ctrl_plane_POF_NI=ones(length(T_D_vect),1);
ctrl_plane_OF_NI=ones(length(T_D_vect),1);
ctrl_plane_POF_RI=ones(length(T_D_vect),1);
ctrl_plane_OF_RI=ones(length(T_D_vect),1);

O_red_POF_NI= ones(length(T_D_vect),length(payload_size_vect));
B_sav_POF_NI= ones(length(T_D_vect),length(payload_size_vect));
O_red_OF_NI= ones(length(T_D_vect),length(payload_size_vect));
B_sav_OF_NI= ones(length(T_D_vect),length(payload_size_vect));

O_red_POF_RI= ones(length(T_D_vect),length(payload_size_vect));
B_sav_POF_RI= ones(length(T_D_vect),length(payload_size_vect));
O_red_OF_RI= ones(length(T_D_vect),length(payload_size_vect));
B_sav_OF_RI= ones(length(T_D_vect),length(payload_size_vect));


for l=1:length(speed_vect)
    for i=1:length(T_D_vect)
        for h=1:length(payload_size_vect)
            
            S_int=Hint+content_name; %[B] Size of Request packet
            S_dat=Hdat+content_name+payload_size_vect(h); %[B] Size of Response packet
            
            H_i_I=Hint+content_name; %[B] Size of Attachment Notification packet
            H_i_D=Hdat+content_name; %[B] Size of Attachment Notification Confirmation packet
            F_r=Hint+content_name; %[B] Size of Face Remove packet
            F_a=Hdat+content_name+content_name; %[B] Size of Face Remove Confirmation packet
            Resync_i=Hint+content_name; %[B] Size of Re-Sync Request packet
            Resync_d=Hdat+content_name+content_name; %[B] Size of Re-sync Response packet
            
            cr=sqrt(10^8/N/pi); %[m] Cell radius
            crt=pi*cr/2/speed_vect(l)*3.6; %[s] Average cell residence time
            crt_net=crt/L; %[s] Average cell residence time of the cosnumers in the network
            
            O_int(i,h)=HTTP_POST+d*S_int+(crt_net./T_D_vect(i))*D*S_int; %[B] Overhead due to the Data Exchange procedure
            O_dat=(A-1)*S_dat; %[B] Overhead due to unuseful data for baseline pull-based approach
            ex_dat=(crt_net./T_D_vect(i))*D*S_dat; %[B] Bandwidth consumed due to exchanged Data packets
            O_tot(i,h)=O_int(i,h)+O_dat; %[B] Overhead for reference pull-based approaches
            
            O_DA=S_dat./(1-exp(-rtt./T_D_vect(i))).*(A+exp(-rtt./T_D_vect(i))-A*exp(-rtt./T_D_vect(i))-exp(-2*rtt./T_D_vect(i))+exp(-(A+1)*rtt./T_D_vect(i))-1); %[B] Overhead due to unuseful data
            O_H=(H_i_I+H_i_D)*d; %[B] Overhead due to the Handover procedure in POF implementation
            O_NI=d*(F_r+F_a)*(2+(k-1)*(A-1)); %[B] Overhead due to the Neighbor Inspection procedure in POF implementation
            O_RI=d*(F_r+F_a)*A;            %[B] Overhead due to the Router Inspection procedure in POF implementation
            O_RS=d*(Resync_i+Resync_d); %[B] Overhead due to the Re-synchronization procedure
            
            OF_H=(OF_PS+OF_PI)*d; %[B] Overhead due to the Handover procedure in OpenFlow implementation
            OF_NI=d*(2*OF_FM+OF_FR)*(2+(k-1).*(A-1)); %[B] Overhead due to the Neighbor Inspection procedure in OpenFlow implementation
            OF_RI=d*(2*OF_FM+OF_FR)*A; %[B] Overhead due to the Router Inspection procedure in OpenFlow implementation
            
            overhead_POF_NI(i,h)=(O_int(i,h)+O_DA+O_H+O_NI+O_RS)/crt_net;%[B/s] Overhead for the POF-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            overhead_POF_RI(i,h)=(O_int(i,h)+O_DA+O_H+O_RI+O_RS)/crt_net;%[B/s] Overhead for the POF-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            overhead_OF_NI(i,h)=(O_int(i,h)+O_DA+OF_H+OF_NI+O_RS)/crt_net;%[B/s] Overhead for the OpenFlow-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            overhead_OF_RI(i,h)=(O_int(i,h)+O_DA+OF_H+OF_RI+O_RS)/crt_net;%[B/s] Overhead for the OpenFlow-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            overhead_RPA(i,h)=O_tot(i,h)/crt_net; %[B/s] Overhead for reference pull-based approaches in a unit of time
            
            data_plane_RPA(i,h)=(O_int(i,h)+O_dat)/crt_net; %[B/s] Average communication overhead on the data plane in a unit of time by reference pull-based approaches
            data_plane_PPA(i,h)=(O_int(i,h)+O_DA+O_RS)/crt_net;   %[B/s] Average communication overhead on the data plane in a unit of time by the proposed protocol architecture
            ctrl_plane_POF_NI(i)=(O_H+O_NI)/crt_net; %[B/s] Average communication overhead on the control plane for the POF-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            ctrl_plane_OF_NI(i)=(OF_H+OF_NI)/crt_net; %[B/s] Average communication overhead on the control plane for the OpenFlow-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            ctrl_plane_POF_RI(i)=(O_H+O_RI)/crt_net; %[B/s] Average communication overhead on the control plane for the POF-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            ctrl_plane_OF_RI(i)=(OF_H+OF_RI)/crt_net; %[B/s] Average communication overhead on the control plane for the OpenFlow-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            
            O_red_POF_NI(i,h)= (overhead_RPA(i,h)-overhead_POF_NI(i,h))/(overhead_RPA(i,h))*100; %[B/s] Overhead reduction for the POF-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            B_sav_POF_NI(i,h)= (overhead_RPA(i,h)-overhead_POF_NI(i,h))/(overhead_RPA(i,h)+ex_dat/crt_net)*100; %[B/s] Bandwidth savings for the POF-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            O_red_OF_NI(i,h)= (overhead_RPA(i,h)-overhead_OF_NI(i,h))/(overhead_RPA(i,h))*100; %[B/s] Overhead reduction for the OpenFlow-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            B_sav_OF_NI(i,h)= (overhead_RPA(i,h)-overhead_OF_NI(i,h))/(overhead_RPA(i,h)+ex_dat/crt_net)*100; %[B/s] Bandwidth savings for the OpenFlow-based Neighbor Inspection implementation of the proposed protocol architecture in a unit of time
            
            O_red_POF_RI(i,h)= (overhead_RPA(i,h)-overhead_POF_RI(i,h))/(overhead_RPA(i,h))*100;   %[B/s] Overhead reduction for the POF-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            B_sav_POF_RI(i,h)= (overhead_RPA(i,h)-overhead_POF_RI(i,h))/(overhead_RPA(i,h)+ex_dat/crt_net)*100; %[B/s] Bandwidth savings for the POF-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            O_red_OF_RI(i,h)= (overhead_RPA(i,h)-overhead_OF_RI(i,h))/(overhead_RPA(i,h))*100; %[B/s] Overhead reduction for the OpenFlow-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            B_sav_OF_RI(i,h)= (overhead_RPA(i,h)-overhead_OF_RI(i,h))/(overhead_RPA(i,h)+ex_dat/crt_net)*100; %[B/s] Bandwidth savings for the OpenFlow-based Router Inspection implementation of the proposed protocol architecture in a unit of time
            
            
        end
    end
    
    
    
    figure('Name',sprintf('N=%d, v=%d km/h, L=%d',N,speed_vect(l),L));
    hold on
    plot(T_D_vect,ctrl_plane_OF_NI,'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,ctrl_plane_OF_RI,':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,ctrl_plane_POF_NI,'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,ctrl_plane_POF_RI,'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    ax = gca;
    set(ax,'yscale','log','FontSize',12)
    set(ax,'xscale','log','FontSize',12)
    xlabel('$T_D \; [s]$','Interpreter','latex','FontSize',15);
    ylabel('$Overhead \; [B/s]$','Interpreter','latex','FontSize',15);
    legend('OpenFlow, Neighbor Inspection','OpenFlow, Router Inspection','POF, Neighbor Inspection','POF, Router Inspection','Interpreter','latex','Location','southeast','FontSize',10);
    ylim([1e0 1e6])
    grid on
    
    f=figure('Name',sprintf('N=%d, v=%d km/h, L=%d',N,speed_vect(l),L));
    plot(T_D_vect,data_plane_RPA(:,1),'--x','Color','b','LineWidth',1.5,'MarkerSize',12)
    hold on
    plot(T_D_vect,data_plane_RPA(:,2),'-.x','Color','b','LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,data_plane_RPA(:,3),':x','Color','b','LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,data_plane_PPA(:,1),'--o','Color','r','LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,data_plane_PPA(:,2),'-.o','Color','r','LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,data_plane_PPA(:,3),':o','Color','r','LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    ax = gca;
    set(ax,'yscale','log','FontSize',12)
    set(ax,'xscale','log','FontSize',12)
    xlabel('$T_D \; [s]$','Interpreter','latex','FontSize',15);
    ylabel('$Overhead \; [B/s]$','Interpreter','latex','FontSize',15);
    legend('Reference pull-based approaches', 'Proposed protocol architecture','Interpreter','latex','Location','southeast','FontSize',10);
    ylim([1e0 1e10])
    yticks([1e0 1e2 1e4 1e6 1e8 1e10])
    grid on
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.329928571428571 0.353809523809525 0.0247142857142857 0.0561904761904775]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.367499999999999 0.358928571428571],...
        [0.323333333333334 0.363333333333334],'String',{'$S_D= 5 \;kB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.323857142857142 0.421428571428573 0.0247142857142857 0.0990476190476179]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.3075 0.324642857142857],...
        [0.540952380952384 0.521428571428572],'String',{'$S_D= 500 \;kB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.331357142857143 0.56904761904762 0.0247142857142857 0.118095238095237]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.393214285714286 0.351785714285714],...
        [0.730952380952382 0.68904761904762],'String',{'$S_D= 50 \;MB$'},...
        'Interpreter','latex');
    
    f=figure('Name',sprintf('N=%d, v=%d km/h, L=%d',N,speed_vect(l),L));
    hold on
    plot(T_D_vect,O_red_OF_NI(:,1),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,O_red_OF_NI(:,2),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_OF_NI(:,3),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_OF_RI(:,1),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,O_red_OF_RI(:,2),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_OF_RI(:,3),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_POF_NI(:,1),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,O_red_POF_NI(:,2),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_POF_NI(:,3),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_POF_RI(:,1),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,O_red_POF_RI(:,2),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,O_red_POF_RI(:,3),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    ax=gca;
    set(ax,'xscale','log','FontSize',12)
    xlabel('$T_D \; [s]$','Interpreter','latex','FontSize',15);
    ylabel('$Overhead \; reduction \; [\%]$','Interpreter','latex','FontSize',15);
    legend('OpenFlow, Neighbor Inspection','OpenFlow, Router Inspection','POF, Neighbor Inspection','POF, Router Inspection','Interpreter','latex','Location','southwest','FontSize',10);
    ylim([-150 100])
    grid on
    
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.587071428571427 0.631904761904765 0.0247142857142857 0.236190476190474]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.614642857142855 0.606071428571427],...
        [0.593809523809527 0.633809523809527],'String',{'$S_D= 5 \;kB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.166714285714285 0.673333333333337 0.0247142857142857 0.0576190476190444]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.195357142857143 0.178571428571429],...
        [0.801904761904763 0.738571428571429],'String',{'$S_D= 500 \;kB$'},...
        'Interpreter','latex');
    
    % Create textarrow
    annotation(f,'textarrow',[0.303928571428571 0.326071428571429],...
        [0.904285714285714 0.889047619047619],'String',{'$S_D= 50 \;MB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.328857142857143 0.849047619047621 0.0247142857142857 0.0566666666666666]);
    
    
    
    f=figure('Name',sprintf('N=%d, v=%d km/h, L=%d',N,speed_vect(l),L));
    hold on
    plot(T_D_vect,B_sav_OF_NI(:,1),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,B_sav_OF_NI(:,2),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_OF_NI(:,3),'--x','Color',[215 0 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_OF_RI(:,1),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,B_sav_OF_RI(:,2),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_OF_RI(:,3),':d','Color',[215 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_POF_NI(:,1),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,B_sav_POF_NI(:,2),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_POF_NI(:,3),'-*','Color',[0 215 0]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_POF_RI(:,1),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12)
    plot(T_D_vect,B_sav_POF_RI(:,2),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    plot(T_D_vect,B_sav_POF_RI(:,3),'-.s','Color',[0 0 215]./256,'LineWidth',1.5,'MarkerSize',12,'HandleVisibility','off')
    ax=gca;
    set(ax,'xscale','log','FontSize',12)
    xlabel('$T_D \; [s]$','Interpreter','latex','FontSize',15);
    ylabel('$Bandwidth \; savings \; [\%]$','Interpreter','latex','FontSize',15);
    legend('OpenFlow, Neighbor Inspection','OpenFlow, Router Inspection','POF, Neighbor Inspection','POF, Router Inspection', 'Interpreter','latex','Location','southwest','FontSize',10);
    ylim([-150 100])
    grid on
    
    % Create textarrow
    annotation(f,'textarrow',[0.790357142857142 0.781785714285714],...
        [0.590000000000002 0.630000000000002],'String',{'$S_D= 5 \;kB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.7685 0.636666666666668 0.0247142857142858 0.235238095238094]);
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.588499999999998 0.854761904761905 0.0247142857142858 0.0495238095238135]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.531785714285714 0.583214285714285],...
        [0.904285714285714 0.887142857142859],'String',{'$S_D= 50 \;MB$'},...
        'Interpreter','latex');
    
    % Create ellipse
    annotation(f,'ellipse',...
        [0.502428571428571 0.797619047619048 0.0247142857142857 0.0457142857142873]);
    
    % Create textarrow
    annotation(f,'textarrow',[0.470357142857143 0.500357142857143],...
        [0.845238095238096 0.82619047619048],'String',{'$S_D= 500 \;kB$'},...
        'Interpreter','latex');
    
    
    
end
