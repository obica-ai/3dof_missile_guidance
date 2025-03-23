function arctan=arctan(z,x)%% for yaw angle
if x>0 
    arctan=-atan(z./x);
elseif x<0&z<0
    arctan=pi-atan(z./x);
else arctan=-pi-atan(z./x);
end