function [R,x,y,retz1,retz2]=straightline(x1,y1,x2,y2)
%%
z1=x1+i*y1;
z2=x2+i*y2;
%%没什么别的意思 为了简单粗暴
if z1==0
	z1=0.00001;
else if abs(z1)==1
	z1=0.9999*z1;
	end
end
z0=(z2-z1)/(1-conj(z1)*z2);
A=i*(z0*conj(z1)-conj(z0)*z1);
B=i*(-z0*(conj(z1)*conj(z1))+conj(z0));
C=-real(B)/A+i*imag(B)/A;
x=real(C);
y=imag(C);
R=sqrt(B*conj(B)/(A*A)-1);
retz1=(z0/abs(z0)+z1)/(1+z0/abs(z0)*conj(z1));
retz2=(-z0/abs(z0)+z1)/(1-z0/abs(z0)*conj(z1));
end