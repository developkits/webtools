# -*- Mode: Perl; perl-indent-level: 2; indent-tabs-mode: nil -*-
# Copyright 2009 Ge van Geldorp
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA

use strict;

package WineTestBot::Config;

=head1 NAME

WineTestBot::Config - Site-independent configuration settings

=cut

use vars qw (@ISA @EXPORT @EXPORT_OK $UseSSL $LogDir $DataDir $BinDir
             $DbDataSource $DbUsername $DbPassword $MaxRevertingVMs
             $MaxRevertsWhileRunningVMs $MaxActiveVMs $MaxVMsWhenIdle
             $SleepAfterRevert $WaitForToolsInVM $MaxTaskTries $AdminEMail
             $RobotEMail
             $WinePatchToOverride $WinePatchCc $SuiteTimeout $SingleTimeout
             $BuildTimeout $ReconfigTimeout $TagPrefix
             $ProjectName $PatchesMailingList $LDAPServer
             $LDAPBindDN $LDAPSearchBase $LDAPSearchFilter
             $LDAPRealNameAttribute $LDAPEMailAttribute $AgentPort $Tunnel
             $TunnelDefaults $JobPurgeDays $JobArchiveDays $WebHostName
             $RegistrationQ $RegistrationARE);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($UseSSL $LogDir $DataDir $BinDir
             $MaxRevertingVMs $MaxRevertsWhileRunningVMs $MaxActiveVMs
             $MaxVMsWhenIdle $SleepAfterRevert $WaitForToolsInVM
             $MaxTaskTries $AdminEMail
             $RobotEMail $WinePatchToOverride $WinePatchCc $SuiteTimeout
             $SingleTimeout $BuildTimeout $ReconfigTimeout
             $TagPrefix $ProjectName $PatchesMailingList
             $LDAPServer $LDAPBindDN $LDAPSearchBase $LDAPSearchFilter
             $LDAPRealNameAttribute $LDAPEMailAttribute $AgentPort $Tunnel
             $TunnelDefaults $JobPurgeDays $JobArchiveDays $WebHostName
             $RegistrationQ $RegistrationARE);
@EXPORT_OK = qw($DbDataSource $DbUsername $DbPassword);

if ($::RootDir !~ m=^/=)
{
    require File::Basename;
    my $name0 = File::Basename::basename($0);
    print STDERR "$name0:error: \$::RootDir must be set to an absolute path\n";
    exit 1;
}

$LogDir = "$::RootDir/var";
$DataDir = "$::RootDir/var";
$BinDir = "$::RootDir/bin";

$MaxRevertingVMs = 1;
$MaxRevertsWhileRunningVMs = 1;
$MaxActiveVMs = 2;
$MaxVMsWhenIdle = undef;
$SleepAfterRevert = 0;
$WaitForToolsInVM = 30;

$MaxTaskTries = 3;

$SuiteTimeout = 30 * 60;
$SingleTimeout = 2 * 60;
$BuildTimeout = 5 * 60;
$ReconfigTimeout = 45 * 60;

$ProjectName = "Wine";
$PatchesMailingList = "wine-patches";

$LDAPServer = undef;
$LDAPBindDN = undef;
$LDAPSearchBase = undef;
$LDAPSearchFilter = undef;
$LDAPRealNameAttribute = undef;
$LDAPEMailAttribute = undef;

$JobPurgeDays = 7;
$JobArchiveDays = 0;

if (!$::BuildEnv)
{
  $::BuildEnv = 0;
  eval 'require "$::RootDir/ConfigLocal.pl"';
  if ($@)
  {
    print STDERR "Please create a valid $::RootDir/ConfigLocal.pl file; " .
        "use $::RootDir/lib/WineTestBot/ConfigLocalTemplate.pl as template\n";
    exit 1;
  }

  require ObjectModel::DBIBackEnd;
  ObjectModel::DBIBackEnd->UseDBIBackEnd('WineTestBot', $DbDataSource,
                                         $DbUsername, $DbPassword,
                                         { RaiseError => 1 });
}

umask 002;

1;
