grub-mkfont  -o dejavu_20.pf2  -s 20 -n dejavu_20 /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
其中 -s 20是指定字体大小  -n dejavu_20 是字体的名字  
bash->: file dejavu_20
可以看到 dejavu_20 Regular 20  也是theme.txt中指定字体要填写的东西


vi /etc/default/grub
在最后添加
GRUB_THEME=/boot/grub/themes/pop/theme.txt
运行 update-grub  重启即可
高分辨率的grub界面反映缓慢
