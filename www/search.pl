#!/usr/bin/env perl

use utf8;
binmode(STDOUT,':utf8');
use strict;
#use warnings;
use Storable;
use CGI;
use Encode;

my $script_uri = './search.pl';
my $stops = retrieve('../stops.store');

my $q = CGI->new;

my $key = Encode::decode('utf-8',$q->param('key'));
my $index = Encode::decode('utf-8',$q->param('index'));

if(defined $key){
	print << "_HTML_";
Content-Type:text/html;charset=utf-8

<html><head><title>search stop</title></head><body>
_HTML_
	unless(defined $stops->{$key}){
		print "not found</body></html>\n";
		exit;
	}

	print "&gt;&gt; $key &lt;&lt;<hr>\n";
	foreach my $i(sort keys %{$stops->{$key}}){
		printf qq(<a href="$script_uri?index=%s">%s</a> ),$q->escape($i),$i;
	}
	print "<hr>search.pl</body></html>\n";
	exit;
}

if(defined $index){
	print << "_HTML_";
Content-Type:text/html;charset=utf-8

<html><head><title>search stops</title></head><body>
_HTML_
	if(length $index == 1){
		unless(defined $stops->{sub_yomi($index)}{$index}){
			print "not found</body></html>\n";
			exit;
		}

		print "&gt;&gt; $index &lt;&lt;<hr>\n";
		foreach my $i(sort keys %{$stops->{sub_yomi($index)}{$index}}){
			printf qq(<a href="$script_uri?index=%s">%s</a> ),$q->escape($i),$i;
		}
	}elsif(length $index == 2){
		my $index1 = remove_dakuon(substr($index,0,1));
		unless(defined $stops->{sub_yomi($index1)}{$index1}{$index}){
			print "not found</body></html>\n";
		}

		print "&gt;&gt; $index &lt;&lt;<hr>\n";
		foreach my $i(sort keys %{$stops->{sub_yomi($index1)}{$index1}{$index}}){
			my $id = $stops->{sub_yomi($index1)}{$index1}{$index}{$i};
			printf qq(<a href="./view.pl?id=%03d">%s</a> ),$id,$i;
		}
	}
	print "<hr>search.pl</body></html>\n";
	exit;
}

print << "_HTML_";
Content-Type:text/html;charset=utf-8

<html><head><title>search stops</title></head><body>
よみから検索<hr>
_HTML_

foreach my $i (sort keys %$stops){
	printf qq(<a href="$script_uri?key=%s">%s</a> ),$q->escape($i),$i;
}

print "<hr>search.pl</body></head>\n";

sub remove_dakuon
{
	my $orig = shift;

	$orig =~ tr/がぎぐげご/かきくけこ/s;
	$orig =~ tr/ざじずぜぞ/さしすせそ/s;
	$orig =~ tr/だぢづでど/たちつてと/s;
	$orig =~ tr/ばびぶべぼ/はひふへほ/s;

	$orig =~ tr/ぱぴぷぺぽ/はひふへほ/s;

	$orig;
}

sub sub_yomi
{
	my $orig = shift;
	
	return 'あ' if($orig =~ /[あいうえお]/);
	return 'か' if($orig =~ /[かきくけこ]/);
	return 'さ' if($orig =~ /[さしすせそ]/);
	return 'た' if($orig =~ /[たちつてと]/);
	return 'な' if($orig =~ /[なにぬねの]/);
	return 'は' if($orig =~ /[はひふへほ]/);
	return 'ま' if($orig =~ /[まみむめも]/);
	return 'や' if($orig =~ /[やゆよ]/);
	return 'ら' if($orig =~ /[らりるれろ]/);
	return 'わ' if($orig =~ /[わをん]/);

	return '';
}


