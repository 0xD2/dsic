#!/usr/bin/perl

#  need: 
#  1. PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
#  2. mysqladmin,netstat,who,exim
#  3. perl

#use strict;
use warnings;
use autodie;  # for auto close opened files

use Getopt::Long;  
use Config::YAML;
#use Data::Dumper;
use POSIX qw(strftime);

GetOptions(
                "dir=s" =>\my $dir,
                "config=s"=>\my $conf,
                "help"=>\my $help
        );

        my $config = Config::YAML->new( config => $conf );

	my $hostname = qx(uname -a); 
	my @netstat = qx(netstat -anp);
	my @diskUsage = qx(df -h);
	my @who = qx(who);
	my @uptime = qx(uptime);
	my @localQueue = qx(exim -bpc);
	my @mysqlProc = qx(mysqladmin processlist);

	
        sub help() {
       		print STDERR <<EOF;
Usage: script.pl --config=/path/to/daily.conf --dir=/path/to/webfolder or "script.pl help" for print help page.
Put this scritp in crontab or run once for a getting current sytem information.
EOF
                exit;
        }

	sub checkSyntax	{
        	if (!$config or !$dir) 	{
                	print "You must specify config, see help:\n\n";
                	help();
        	}
	}

	checkSyntax();


	my $cur_date = strftime "%d%m%Y", localtime;
	my $cur_full_time = strftime "%H:%M:%S %Z %e-%b-%Y", localtime;

	open (my $htmlFile, '>>', "$dir/$cur_date.html") or die "error: $@";
	print $htmlFile "<html><head> <title>Daily report $cur_date</title></head><body>";
	
	print $htmlFile "<p>System: <b>$hostname</b></p>";
	
	sub printLines {
                my $descriptor = ${$_[0]};
                my @lines = @{$_[1]};
		my $message = $_[2];
		print $descriptor "<p>".$message."</p>";
                print $descriptor "<pre>";
                  foreach my $i (@lines) {
                  print $descriptor "$i";
                }
		print $descriptor "</pre>";
        }

	### uptime 
	if (($config->{'uptime'}) eq "yes")         {   printLines(\$htmlFile, \@uptime, "Uptime:");       }
	### who
	if (($config->{'who'}) eq "yes")         { 	printLines(\$htmlFile, \@who, "Who online:");  	}
	### disk usage
	if (($config->{'du'}) eq "yes")         { 	printLines(\$htmlFile, \@diskUsage, "Disk Usage:");    }	
	### netstat 
	if (($config->{'netstat'}) eq "yes")         { 	printLines(\$htmlFile, \@netstat, "Network interfaces: ");     }
	### mail queue
	if (($config->{'exim'}) eq "yes")         {  	printLines(\$htmlFile, \@localQueue, "Messages in mail queue: ");   }
	### mysql admin
	if (($config->{'mysql'}) eq "yes")         { 	printLines(\$htmlFile, \@mysqlProc, "Show MySQL process list: "); 	}

	
	print $htmlFile "<p>Page generated: $cur_full_time</p></body></html>";
             
	close ($htmlFile); 
	
