clear,clc;
s=0.01;%stepsize
N=4;%
g=9.81;% gravitational acceleration
%%Initialization
vm=1000;
vt=500;
theta_missile=0.82;
theta_target=0.0845;
psi_missile=0.06;
psi_target=0;


% initial position
missile_position_ground(1,:) = [0 0 0];
target_position_ground(1,:) = [4000 3000 200];

missile_velocity_ground(1,:) = [vm.*cos(theta_missile).*cos(psi_missile),vm.*sin(theta_missile),-vm.*cos(theta_missile).*sin(psi_missile)];
target_velocity_ground(1,:) = [vt.*cos(theta_target).*cos(psi_target),vt.*sin(theta_target),-vt.*cos(theta_target).*sin(psi_target)];


ct = 1;

while 1
    missile_x = missile_velocity_ground(ct,1);
    missile_y = missile_velocity_ground(ct,2);
    missile_z = missile_velocity_ground(ct,3);

    target_x = target_velocity_ground(ct,1);
    target_y = target_velocity_ground(ct,2);
    target_z = target_velocity_ground(ct,3);

    theta_missile(ct) = atan(missile_y./sqrt(missile_x.^2 + missile_z.^2));
    psi_missile(ct) = arctan(missile_z,missile_x);
    theta_target(ct) = atan(target_y ./ sqrt(target_x.^2 + target_z.^2));
    psi_target(ct) = arctan(target_z,target_x);
    
    % relative position and velocity
    rel_posi(ct,:) = target_position_ground(ct,:) - missile_position_ground(ct,:);
    rel_velo(ct,:) = target_velocity_ground(ct,:) - missile_velocity_ground(ct,:);

    % pitch angle and yaw angle of LOS
    LOS_x = rel_posi(ct,1);
    LOS_y = rel_posi(ct,2);
    LOS_z = rel_posi(ct,3);

    LOS_xv = rel_velo(ct,1);
    LOS_yv = rel_velo(ct,2);
    LOS_zv = rel_velo(ct,3);


    theta_LOS(ct) =atan(LOS_y ./ sqrt(LOS_x.^2 + LOS_z.^2));
    psi_LOS(ct) = arctan(LOS_z,LOS_x);

    % change rate of LOS
    theta_rate_LOS(ct) = ((LOS_x.^2 + LOS_z.^2).*LOS_yv- LOS_y.*(LOS_x.*LOS_xv + LOS_z.*LOS_zv))./((LOS_x.^2+LOS_y.^2+LOS_z.^2).*sqrt(LOS_x.^2+LOS_z.^2)); 
    psi_rate_LOS(ct) = (LOS_z.*LOS_xv-LOS_x.*LOS_zv)./(LOS_x.^2+LOS_z.^2);


    % Guidance solution
    LOS_relv(:,ct) = R(theta_LOS(ct),psi_LOS(ct)) * rel_velo(ct,:)';
    LOS_Vr = LOS_relv(1,ct);
    
    % guidance acceleration

    amyc = N.*abs(LOS_Vr).*theta_rate_LOS(ct);
    amzc = -N.* abs(LOS_Vr).*psi_rate_LOS(ct).*cos(theta_LOS(ct));
    am(ct,:) = [0,amyc,amzc];


    % global acceleration variable for integral
    global AM;

    AM = R(theta_missile(ct),psi_missile(ct))*R(theta_LOS(ct),psi_LOS(ct))' * am(ct,:)';
    am1(ct,:) = AM;
    

    % trajectory integral
    tspan = [0,s];
    
    global V0;

    traj_mv(:,ct) = R(theta_missile(ct),psi_missile(ct))* missile_velocity_ground(ct,:)';
    traj_tv(:,ct) = R(theta_target(ct),psi_target(ct))* target_velocity_ground(ct,:)';

    %initial integral value
    V0 = [traj_mv(:,ct);traj_tv(:,ct)];
    
    [T1,V]=ode45(@f1,tspan,V0');
    v(ct+1,:)=V(end,:)';
    traj_mp(:,ct) = R(theta_missile(ct),psi_missile(ct))*missile_position_ground(ct,:)';
    traj_tp(:,ct) = R(theta_target(ct),psi_target(ct))* target_position_ground(ct,:)';
    
    % missile initial(precedes position 
    P0 = [traj_mp(:,ct);traj_tp(:,ct)];

    [T2,P]=ode45(@f2,tspan,P0');
    p(ct+1,:) = P(end,:)';

    % update each  for next iteration

    missile_position_ground(ct+1,:) = R(theta_missile(ct),psi_missile(ct))'*[p(ct+1,1);p(ct+1,2);p(ct+1,3)];
    target_position_ground(ct+1,:) = R(theta_target(ct),psi_target(ct))'*[p(ct+1,4);p(ct+1,5);p(ct+1,6)];
    missile_velocity_ground(ct+1,:) = R(theta_missile(ct),psi_missile(ct))'*[v(ct+1,1);v(ct+1,2);v(ct+1,3)];
    target_velocity_ground(ct+1,:) = R(theta_target(ct),psi_target(ct))'*[v(ct+1,4);v(ct+1,5);v(ct+1,6)];
    dist(ct) = norm(rel_posi(ct,:));

    if dist(ct) < 50
        break;
    end

    ct = ct + 1;
end

figure;
plot3(missile_position_ground(:,1),missile_position_ground(:,3),missile_position_ground(:,2),'r',target_position_ground(:,1),target_position_ground(:,3),target_position_ground(:,2),'b');%画出导弹目标运动轨迹
grid on;set(gca,'YDir','reverse'); %令y轴刻度反向
text(missile_position_ground(50,1),missile_position_ground(50,3),missile_position_ground(50,2),'\leftarrow Guidance ratio');%给导弹轨迹加标注
text(target_position_ground(50,1),target_position_ground(50,3),target_position_ground(50,2),'\leftarrow Target');%给目标轨迹加标注
text(missile_position_ground(ct,1),missile_position_ground(ct,3),missile_position_ground(ct,2),'\leftarrow Hit');
xlabel('X(m)');ylabel('Z(m)');zlabel('Y(m)');%给三维图加坐标轴标注
legend('Missile','Target');


sprintf('Hit Time: %3.4f',s*ct)% total hit time
figure;
plot(s*(1:ct),dist);% distance / time
grid on;xlabel('time/s');ylabel('distance/m');


figure;
plot(s*(1:ct),LOS_relv(1,:),'r',s*(1:ct),LOS_relv(2,:),'m',s*(1:ct),LOS_relv(3,:),'b');%画出视线系下的相对速度
hold on,plot([0 10],[0 0],'--');%画y=0的辅助线
xlabel('time(sec)');ylabel('Speed(m/s)');legend('LOS x aixs relative speed','LOS y aixs relative speed','LOS z aixs relative speed');


%% velocity derivatives
function dv=f1(t,v)
global AM;
dv=zeros(6,1);%
%derivatives，dv(1),dv(2),dv(3)missile speed changed rate on traject；dv(4),dv(5),dv(6) target speed；
dv(1)=AM(1);
dv(2)=AM(2);
dv(3)=AM(3);
dv(4)=1*cos(t);
dv(5)=0;
dv(6)=0;
end
function dr=f2(t,r)
global V0;
dr=zeros(6,1);
%dv，dr(1),dr(2),dr(3)missile position；dr(4),dr(5),dr(6)target position；
dr(1)=V0(1);
dr(2)=V0(2);
dr(3)=V0(3);
dr(4)=V0(4);
dr(5)=V0(5);
dr(6)=V0(6);
end
