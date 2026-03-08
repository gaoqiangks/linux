#!/usr/bin/perl
use 5.010;
sub wsltolinux{
	my $path= shift;
	#$path='\\wsl.localhost\Ubuntu\home\gaoqiang\latex\DR\DR-MC-II-G.tex';
	$path=~s/\\wsl.*\\home/\\home/;
	$path=~s/\\/\//g;
	return $path;
}
my $path=$ARGV[0];
my $linen=$ARGV[1];
my $linuxpath=wsltolinux($path);
#my $linen=350;
my $cmd='nvim --headless -c "VimtexInverseSearch '.$linen." "."'".$linuxpath."'"."\" &";
`echo $ARGV[0] $cmd > /tmp/cmd.txt`;
`$cmd`;
$cmd='nvim --headless -c "zz" &';
`$cmd`;
