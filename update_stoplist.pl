#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Storable;
binmode(STDOUT, ":utf8");

my $stopdata = './stops.store';
my $iddata = './id.store';
my $stop_cache  = './stops/*.store';

use LWP::Simple;
use HTML::TableExtract;

my $content = get('http://www.city.kyoto.jp/kotsu/bls/help/p_code_table.htm');
my $te = HTML::TableExtract->new();
$te->parse($content);

#my %id;
#my(%index1,%index2,%index3);
my $stops={};
my $ids = {};
#open(my $fh,'>:utf8', $stopcsv) or die "cannot open[$stopcsv]:$!";
foreach my $row ($te->rows){
	next unless $row->[3] =~/^[0-9]+/;
	my $head2=remove_dakuon(substr($row->[1],0,1));
	my $head3=substr($row->[1],0,2);
	my $head1=sub_yomi($head2);

	$stops->{$head1} = {} unless(defined $stops->{$head1});
	$stops->{$head1}{$head2} = {} unless(defined $stops->{$head1}{$head2});
	$stops->{$head1}{$head2}{$head3} = {} unless(defined $stops->{$head1}{$head2}{$head3});
	$stops->{$head1}{$head2}{$head3}{$row->[0]} = $row->[3];

	$ids->{$row->[3]} = $row->[0].','.$row->[1].','.$row->[2];
}

store $stops, $stopdata;
store $ids,$iddata;
unlink glob $stop_cache;

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
