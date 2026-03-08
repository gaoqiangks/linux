function []=geodesic(x1,y1,x2,y2)
[R,x0,y0,sz,dz]=straightline(x1,y1,x2,y2);
a=angle(sz-(x0+i*y0));
b=angle(dz-(x0+i*y0));
d=max(a,b);
s=min(a,b);
if x0>0
	if s*d<0
		s=s+2*pi;
		tmp=d;
		d=s;
		s=tmp;
	end
end
iter=s:1/1000:d+1/1000;
x=x0+R*cos(iter);
y=y0+R*sin(iter);
plot(x,y,'k'),axis equal;
hold on;
iter=0:pi/100:2*pi;
x=cos(iter);
y=sin(iter);
axis([-1,1,-1,1]);
plot(x,y,'r','linewidth',1),axis equal;
plot(x1,y1,'.'),axis equal;
plot(x2,y2,'.'),axis equal;
plot(real(sz),imag(sz),'*'),axis equal;
plot(real(dz),imag(dz),'o'),axis equal;
end