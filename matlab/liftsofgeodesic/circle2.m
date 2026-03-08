function []=circle2(x0,y0,r)
i=0:pi/100:2*pi;
x=x0+r*cos(i);
y=y0+r*sin(i);
plot(x,y,'-'),axis equal;
end