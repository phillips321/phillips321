#!/usr/bin/env perl
#
# winlanfoe - Windows information collation tool
# Copyright (C) 2012 Richard Hatch
# 
# This tool may be used for legal purposes only.  Users take full responsibility
# for any actions performed using this tool.  The author accepts no liability
# for damage caused by this tool.  If these terms are not acceptable to you, then
# you are not permitted to use this tool.
#
# In all other respects the GPL version 2 applies:
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# You are encouraged to send comments, improvements or suggestions to
# me at rgh@portcullis-security.com
#
use strict;
use warnings;
use File::Basename;

my $script_name = basename($0);

print " $script_name v0.4 (http://labs.portcullis.co.uk/application/winlanfoe/)\n";
print " Copyright (C) 2012 Richard Hatch (rgh\@portcullis-security.com)\n";

my $usage = "
  Parses enum4linux output for Windows for hostname, workgroup/domain, domain-member, OS.

  Usage:
  ./$script_name enum4linux-10.0.0.1.out [ enum4linux-10.0.0.2.out ]
 or 
  ./$script_name -f   # To search the current directory tree for enum4linux files

";

my $file;
my @src_files = ();

if ($#ARGV < 0) {
	die $usage;
}

if ("$ARGV[0]" eq "-f" ) {
	@src_files = split("\n", `find | grep -i enum4linux`);
}
else {
	@src_files =  <@ARGV>;
}

my $rec = {}; #temp record. used to record information prior to inserting into %hosts
my $hostname;
my $wg_domain_name;
my $wg_or_domain;
my $domain;
my $msbrowse;
my $OS = "";
my $is_DC;	
my %hosts;

my @Domain_WG_Names = (); #holds the names of domains/workgroups identified
my @Domain_Controllers = (); #holds the hostnames of domain controllers identified (by Domain Controllers entry)
my @Domains = (); #Holds the names of domain names positively identified (by Comain Controllers entry)
my %hosts_info = (); #holds the host information for each host (enum4linux output) encountered
my @Workgroups = (); #holds the names of workgroups, i.e. domain names for which no domain controller found

#These are used for formating the output
my $Max_Domain_Length = 0;
my $Max_Workgroup_length = 0;
my $Max_Hostname_Length = 0;
my $Max_OS_Length = 0;
my $Max_IP_Length = 0;

my $filename = "";
my $ip = "";

#Temporary variables
my $h; 
my $t;
my $k;
my $i;

print "\nNote: OS Version is taken from enum4linux. You might get more precise results with:\n # msfcli auxiliary/scanner/smb/smb_version RHOSTS=1.2.3.4 e, or examining nessus output\n\n";


foreach (@src_files) {
	$filename = $_;
	$hostname = "";
	$wg_domain_name=  "";
	$wg_or_domain = "";
	$domain = "";
	$msbrowse = 0;
	$OS = "";
	$is_DC = 0;

	if ($filename =~ /(\d+\.\d+\.\d+\.\d+)/) {
		$ip = $1;
		#next;
	}


	#my $ip = $1;

	unless (open(FILE, "<$filename")) {
		print "WARNING: Can't open $filename for reading.  Skipping...\n";
		next;
	}

	while (<FILE>) {
		chomp;
		my $line = $_;

		if ($line =~ /(\d+\.\d+\.\d+\.\d+)/) {
			$ip = $1;
		}

		if ($line =~ /\s*([A-Za-z0-9-_.]+)\s.*\sWorkstation\sService/) {
			$hostname = $1;
			if (length($hostname) > $Max_Hostname_Length) {
				$Max_Hostname_Length = length($hostname);
			}
		}

		if ($line =~ /\s*([A-Za-z0-9-_.]+)\s.*\sDomain\/Workgroup\sName/) { 
			$wg_domain_name = $1;
		}

		if ( $line =~ /\s*([A-Za-z0-9-_.]+)\s.*\sDomain\sControllers/) {
			$is_DC = 1;
			$domain = $1;
		}
		if ( $line =~ /\s*..__MSBROWSE__.\s/) {
			$msbrowse = 1;
		}
		if ( $line =~ /\s*OS\=\[(.*)\]\sServer=/) {
			$OS = $1;
			if ("$OS" eq "Windows 5.1") {
				$OS = "Windows 5.1 (XP)";
			}
			if ("$OS" eq "Windows 5.0") {
				$OS = "Windows 5.0 (2000)";
			}
			if (length($OS) > $Max_OS_Length) {
				$Max_OS_Length = length($OS);
			}
		}
		if ("x$OS" eq "x") {
			$OS = "** Not identified **";
		}

	}#end while <FILE>
	if (length($ip) > $Max_IP_Length) {
		$Max_IP_Length = length($ip);
	}

	$rec = {}; #init a temporary record

	$rec->{hostname} = $hostname;
	$rec->{IP} = $ip;
	$rec->{OS} = $OS;
	$rec->{IS_DC} = $is_DC;

	$rec->{Domain_WG_Name} = $wg_domain_name;
	
	if (! is_in_domains_array($wg_domain_name))
	{
		push @Domain_WG_Names, $wg_domain_name;
	}

	if ($is_DC) {
		
		if (! is_in_domains_array($wg_domain_name))
		{
			push @Domains, $wg_domain_name;
		}
	}
	$hosts_info{ $rec->{hostname} } = $rec; #add tempoary record to list

}#end while shift


#which domain names do not have a domain controller?
foreach $h (@Domain_WG_Names) {
	if ( ! is_in_domains_array($h) ) {
		if ( ! is_in_workgroups_array($h)) {
			push @Workgroups, $h;
		}
	}
} #end foreach $h (@domain_WG_Names)

#Calculate the max lengths
foreach $h (@Domains) {
	if (length($h) > $Max_Domain_Length) {
		$Max_Domain_Length = length($h);
	}
} #end foreach $h (@Domains)

foreach $h (@Workgroups) {
	if (length($h) > $Max_Workgroup_length) {
		$Max_Workgroup_length = length($h);
	}
} #end foreach $h (@Workgroups)

my $Max_Dom_WG_Length = $Max_Domain_Length;

if ($Max_Workgroup_length > $Max_Domain_Length)
{
	$Max_Dom_WG_Length = $Max_Workgroup_length;
}


#Sort be Domain/Workgroup name
@Domains = sort(@Domains);
@Workgroups = sort(@Workgroups);

#Output Domain information

foreach $h (@Domains) {
	foreach $i (keys %hosts_info) {
		if ($hosts_info{$i}{Domain_WG_Name} eq $h)
		{#we found a member of current Domain

			print "Domain: ";
			$k = sprintf("%-*s", $Max_Dom_WG_Length+2, "$h, ");
			print $k;

			print "Hostname: ";
			$k = sprintf("%-*s",$Max_Hostname_Length+2,"$i, ");
			print "$k";

			print "IP: ";
			$k = sprintf("%-*s",$Max_IP_Length+2, "$hosts_info{$i}{IP}, ");
			print $k;

			print "OS: ";
			$k = sprintf("%-*s", $Max_OS_Length+2, "$hosts_info{$i}{OS}, ");
			print $k;

			if ($hosts_info{$i}{IS_DC} == 1) {
				print "Domain Controller";
			}
			print "\n";
		}#end we found a member of the current domain
	}#end foreach $i keys %hosts_info
}#end foreach $h (@Domains)

print "\n";

#Output Workgroup information

foreach $h (@Workgroups) {
	foreach $i (keys %hosts_info) {
		if ($hosts_info{$i}{Domain_WG_Name} eq $h)
		{#we found a workgroup member
			print "Wrkgrp: ";
			$k = sprintf("%-*s", $Max_Dom_WG_Length+2,"$h, ");
			print $k;

			print "Hostname: ";
			$k = sprintf("%-*s",$Max_Hostname_Length+2,"$i, ");
			print "$k";

			print "IP: ";
			$k = sprintf("%-*s",$Max_IP_Length+2, "$hosts_info{$i}{IP}, ");
			print $k;

			print "OS: ";
			$k = sprintf("%-*s", $Max_OS_Length+2, "$hosts_info{$i}{OS}, ");
			print $k;
			print "\n";
		}#end if we found a workgroup member
	}#end foreach $i keys %hosts_info
}#end foreach $h 

print "\n";


sub is_in_domains_array #(wg_dom_name)
{
	my $searchStr = $_[0];
	my $found;
	$found = 0;
	for my $i (@Domains)
	{
		if ("$i" eq "$searchStr")
		{
			$found = 1;
		}
	}
	$found; #return value
}#end sub is_in_domains_array

sub is_in_workgroups_array #(wg_dom_name)
{
	my $searchStr = $_[0];
	my $found;
	$found = 0;
	for my $i (@Workgroups)
	{
		if ("$i" eq "$searchStr")
		{
			$found = 1;
		}
	}
	$found; #return value
}#end sub is_in_domains_array

#EOF

