#!/usr/bin/env perl

use strict;
#use warnings;
use utf8;
use Encode;
use CGI;
use LWP::Simple;
use Storable;
use HTML::TreeBuilder;
use URI;

binmode(STDOUT, ":utf8");

my $id = retrieve('../id.store');
my $stop_cache = '../stops/';

my $q = CGI->new;

my $num = $q->param('id');

unless($num =~ /^\d{1,3}/){
	print "Content-Type:text/plain;charset=utf-8\n\n";
	print "invalid param\n";
	exit;
}
$num = sprintf('%03d',$num+0);
unless(defined $id->{$num}){
	print "Content-Type:text/plain;charset=utf-8\n\n";
	print "stop not found\n";
	exit;
}


my($name,$yomi) = split(/,/,$id->{$num});
my $timetable = sprintf 'http://www.city.kyoto.jp/kotsu/busdia/m/%03d.shtm',$num;
print << "_HTML_";
Content-Type:text/html;charset=utf-8

<html><head><title>$name($yomi)</title></head><body>
$name No.$num [<a href="$timetable">時刻表</a>]
<hr>
_HTML_

foreach my $info(get_stop_list($num)){
	printf qq(%s <a href="%s-1211">%s</a><br>\n),$info->{num},$info->{link},$info->{bound};
}

print << "_HTML_";
<hr>view.pl</body></html>
_HTML_

sub get_stop_list
{
	my $stop_id = shift;

	my $cache = sprintf '%s/%03d.store',$stop_cache,$stop_id;
	if(-e $cache){
		my $cached_data = retrieve $cache;
		return @$cached_data;
	}

	my $content;
	my $i = 1;

	my @stops;
	do{
		$content = get_content($stop_id,$i);
		push(@stops,get_stop_list_per_page($content));
	
		$i++;	
	}while(exist_next($content));

	store \@stops,$cache;

	@stops;
}

sub get_content
{
	my($code,$page) = @_;
	my $uri = sprintf('http://www.city.kyoto.jp/kotsu/bls/m/%03dp%1d.shtm',$code,$page);
	get($uri);
}

sub exist_next
{
	my $body = shift;

	return undef unless defined $body;
	my $tree = HTML::TreeBuilder->new;
	$tree->parse($body);
	foreach my $a($tree->find('a')){
		$a->detach;
		if($a->as_text eq '次頁'){
			return $a;
		}
	}
	undef;
}

sub get_stop_list_per_page
{
	my $body = shift;

	my $tree = HTML::TreeBuilder->new;
	$tree->parse($body);
	my $stops = $tree->look_down(_tag => 'dl');
	my $last_stop;
	my @stop_list;

	foreach my $stop ($stops->detach_content){
		if($stop->tag eq 'dt'){
			$last_stop = $stop;
			next;
		}
		my $info = $last_stop->find('a');

		push(@stop_list,{
				num   => $info->as_text,
				bound => $stop->as_text,
				link  => URI->new_abs($info->attr('href'),'http://www.city.kyoto.jp/kotsu/bls/index.shtm'),
			});
	
		$last_stop = undef;
	}
	@stop_list;
}

