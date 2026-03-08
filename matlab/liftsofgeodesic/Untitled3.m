for r=1:100
i=0:pi/100:2*pi;
x=1+r*cos(i);
y=1+r*sin(i);
plot(x,y,'-'),axis equal;
end