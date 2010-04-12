# Base class for web pages
#
# Copyright 2009 Ge van Geldorp
# Copyright 2010 VMware, Inc.
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

=head1 NAME

WineTestBot::CGI::PageBase - Base class for web pages

=cut

package WineTestBot::CGI::PageBase;

use Apache2::Const -compile => qw(REDIRECT);
use Apache2::ServerRec;
use CGI::Cookie;
use URI::Escape;
use WineTestBot::CGI::Sessions;
use WineTestBot::Config;
use WineTestBot::Utils;

use vars qw(@ISA @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&CreatePageBase);

sub new
{
  my $class = shift;
  my ($Page, $Request, $RequiredRole) = @_;

  my $self = {Request => $Request,
              Session => undef};
  $self = bless $self, $class;

  if (defined($RequiredRole) && $RequiredRole ne "")
  {
    $self->CheckSecurePage();
    my $Session = $self->GetCurrentSession();
    if (! defined($Session) ||
        ! $Session->User->HasRole($RequiredRole))
    {
      my $LoginURL = "/Login.pl?Target=" . uri_escape($ENV{"REQUEST_URI"});
      $self->Redirect($Page, MakeSecureURL($LoginURL));
    }
  }

  $self->_initialize(@_);
  return $self;
}

sub _initialize
{
}

sub CheckSecurePage
{
  my $self = shift;
  my $Page = $_[0];

  if (! $UseSSL || SecureConnection())
  {
    return;
  }

  $self->Redirect($Page, MakeSecureURL($ENV{"REQUEST_URI"}));
}

sub GenerateHttpHeaders
{
  my $self = shift;

  my $Request = $self->{Request};

  # Date in the past
  $Request->headers_out->add("Expires", "Sun, 25 Jul 1997 05:00:00 GMT");

  # always modified
  $Request->headers_out->add("Last-Modified", (scalar gmtime) . " GMT");

  # HTTP/1.1
  $Request->headers_out->add("Cache-Control", "no-cache, must-revalidate, " .
                                              "post-check=0, pre-check=0");

  # HTTP/1.0
  $Request->headers_out->add("Pragma", "no-cache");

  # Force char set
  $Request->content_type("text/html; charset=UTF-8");

  $self->SetCookies();
}

sub UnsetCookies
{
  my $self = shift;

  my $Request = $self->{Request};
  my %Cookies = CGI::Cookie->fetch($Request);
  if (defined($Cookies{"SessionId"}))
  {
    my $Cookie = CGI::Cookie->new(-Name    => "SessionId",
                                  -Value   => "deleted",
                                  -Expires => "Sun, 25 Jul 1997 05:00:00 GMT",
                                  -Domain  => $ENV{"HTTP_HOST"},
                                  -Path    => "/",
                                  -Secure  => $UseSSL);
    $Request->err_headers_out->add("Set-Cookie", $Cookie);
  }
  if (defined($Cookies{"SessionActive"}))
  {
    my $Cookie = CGI::Cookie->new(-Name    => "SessionActive",
                                  -Value   => "deleted",
                                  -Expires => "Sun, 25 Jul 1997 05:00:00 GMT",
                                  -Domain  => $ENV{"HTTP_HOST"},
                                  -Path    => "/",
                                  -Secure  => !1);
    $Request->err_headers_out->add("Set-Cookie", $Cookie);
  }
  delete $Request->headers_in->{"Cookie"};
}

sub SetCookies
{
  my $self = shift;

  my $Request = $self->{Request};
  if ($self->SessionActive())
  {
    my $Session = $self->GetCurrentSession();
    my $Expire, my $SessionPermanent, my $Cookie;
    if (defined($Session))
    {
      if ($Session->Permanent)
      {
        $Expire = 2 ** 31 - 1;
        $SessionPermanent = "P";
      }
      else
      {
        $Expire = undef;
        $SessionPermanent = "T";
      }

      $Cookie = CGI::Cookie->new(-Name    => "SessionId",
                                 -Value   => $Session->Id,
                                 -Expires => $Expire,
                                 -Domain  => $ENV{"HTTP_HOST"},
                                 -Path    => "/",
                                 -Secure  => $UseSSL);
      $Request->err_headers_out->add("Set-Cookie", $Cookie);
    }
    else
    {
      my %Cookies = CGI::Cookie->fetch($Request);
      $SessionPermanent = $Cookies{"SessionActive"}->value;
      if ($SessionPermanent eq "P")
      {
        $Expire = 2 ** 31 - 1;
      }
      else
      {
        $Expire = undef;
      }
    }
    
    $Cookie = CGI::Cookie->new(-Name    => "SessionActive",
                               -Value   => $SessionPermanent,
                               -Expires => $Expire,
                               -Domain  => $ENV{"HTTP_HOST"},
                               -Path    => "/",
                               -Secure  => !1);
    $Request->err_headers_out->add("Set-Cookie", $Cookie);
  }
  else
  {
    $self->UnsetCookies();
  }
}

sub GenerateHeader
{
  my $self = shift;
  my $Page = $_[0];

  print <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <title>${ProjectName} Test Bot</title>
  <link rel="stylesheet" href="/${ProjectName}TestBot.css" type="text/css" media="screen">
</head>
EOF
  
  print "<body";
  my $OnLoadJavascriptFunction = $self->GetOnLoadJavascriptFunction($Page);
  if ($OnLoadJavascriptFunction)
  {
    print " onload='$OnLoadJavascriptFunction'";
  }
  print ">\n";

  print <<EOF;

<div id="logo_blurb">
${ProjectName} Test Bot
</div>

<div id="main_content">
  <div id="header">
    <div id="menu">
      <ul>
        <li class='top'><p>Test Bot</p></li>
        <li><p><a href='/index.pl'>Home</a></p></li>
        <li class='divider'>&nbsp;</li>
        <li><p><a href='/PatchesList.pl'>Wine-patches</a></p></li>
EOF

  my $Session = $self->GetCurrentSession();
  if ($self->SessionActive())
  {
    print "        <li class='divider'>&nbsp;</li>\n";
    print "        <li><p><a href='", MakeSecureURL("/Submit.pl"),
          "'>Submit job</a></p></li>\n";
    print "        <li class='divider'>&nbsp;</li>\n";
    print "        <li><p><a href='", MakeSecureURL("/Logout.pl"), "'>Log out";
    if (defined($Session))
    {
      print " ", $Page->CGI->escapeHTML($Session->User->Name);
    }
    print "</a></p></li>\n";
  }
  else
  {
    print "        <li class='divider'>&nbsp;</li>\n";
    print "        <li><p><a href='/Register.pl'>Register</a></p></li>\n";
    print "        <li class='divider'>&nbsp;</li>\n";
    print "        <li><p><a href='", MakeSecureURL("/Login.pl"),
          "'>Log in</a></p></li>\n";
  }
  print "        <li class='divider'>&nbsp;</li>\n";
  print "        <li><p><a href='/Feedback.pl'>Feedback</a></p></li>\n";
  print "        <li class='bot'>&nbsp;</li>\n";
  if (defined($Session) && $Session->User->HasRole("admin"))
  {
    print "        <li class='top'><p>Admin</p></li>\n";
    print "        <li><p><a href='", MakeSecureURL("/admin/UsersList.pl"),
          "'>Users</a></p></li>\n";
    print "        <li class='divider'>&nbsp;</li>\n";
    print "        <li><p><a href='", MakeSecureURL("/admin/VMsList.pl"),
          "'>VMs</a></p></li>\n";
    print "        <li class='bot'>&nbsp;</li>\n";
  }

  print <<EOF;
      </ul>
    </div>
    <div id="banner">
      <div id="Logo">
        <a href="/index.pl"><img src="/${ProjectName}Logo.png" alt=""></a>
      </div>
    </div>
  </div>

  <div class="rbox">
    <b class="rtop"><b class="r1">&nbsp;</b><b class="r2">&nbsp;</b><b class="r3">&nbsp;</b><b class="r4">&nbsp;</b></b>
    <div id="ContentContainer">
EOF
}

sub GenerateFooter
{
  my $self = shift;

  print <<EOF;
    </div>
    <b class="rbottom"><b class="r4">&nbsp;</b><b class="r3">&nbsp;</b><b class="r2">&nbsp;</b><b class="r1">&nbsp;</b></b>
  </div>
</div>

</body>
</html>
EOF
}

sub GenerateErrorDiv
{
  my $self = shift;
  my $Page = shift;

  my $ErrMessage = $Page->GetErrMessage();
  if ($ErrMessage)
  {
    print "<noscript>\n";
    print "<div id='errormessage'>", $ErrMessage, "</div>\n";
    print "</noscript>\n";
  }
}

sub GenerateErrorPopup
{
  my $self = shift;
  my $Page = shift;

  my $ErrMessage = $Page->GetErrMessage();
  if ($ErrMessage)
  {
    print "<script type='text/javascript'>\n";
    print "<!--\n";
    $ErrMessage =~ s/'/\\'/g;
    print "function ShowError() { alert('", $ErrMessage, "'); }\n";
    my $ErrField = $Page->GetErrField();
    if ($ErrField)
    {
      print "document.forms[0].", $ErrField, ".focus();\n";
    }
    print "//-->\n";
    print "</script>\n";
  }
}

sub GenerateBody
{
  my $self = shift;

  die "Pure virtual function " . ref($self) . "::GenerateBody called";
}

sub GetOnLoadJavascriptFunction
{
  my $self = shift;
  my $Page = $_[0];

  if ($Page->GetErrMessage())
  {
    return "ShowError()";
  }

  return undef;
}

sub Redirect
{
  my $self = shift;
  my ($Page, $Location) = @_;

  $self->SetCookies();
  if (substr($Location, 0, 4) ne "http")
  {
    my $Protocol = "http";
    if (SecureConnection())
    {
      $Protocol .= "s";
    }
    if (substr($Location, 0, 1) ne "/")
    {
      my $URI = $self->{Request}->uri;
      $URI =~ s=^(.*)/[^/]*$=$1/=;
      $Location = $URI . $Location;
    }
    my $Server = $self->{Request}->server;
    $Location = $Protocol . "://" . $Server->server_hostname . $Location; 
  }
  $self->{Request}->headers_out->set("Location", $Location);
  $self->{Request}->status(Apache2::Const::REDIRECT);
  exit;
}

sub GetCurrentSession
{
  my $self = shift;

  if ($UseSSL && ! SecureConnection())
  {
    return undef;
  }

  if (! defined($self->{Session}))
  {
    my %Cookies = CGI::Cookie->fetch($self->{Request});
    if (defined($Cookies{"SessionId"}))
    {
      my $SessionId = $Cookies{"SessionId"}->value;
      my $Sessions = CreateSessions();
      $self->{Session} = $Sessions->GetItem($SessionId);
    }
  }

  return $self->{Session};
}

sub SetCurrentSession
{
  my $self = shift;
  my ($Page, $Session) = @_;

  $self->{Session} = $Session;
  if (! defined($Session))
  {
    $self->UnsetCookies();
  }
}

sub SessionActive
{
  my $self = shift;

  if (defined($self->GetCurrentSession()))
  {
    return 1;
  }

  my %Cookies = CGI::Cookie->fetch($self->{Request});
  if ($UseSSL && ! SecureConnection() && defined($Cookies{"SessionActive"}))
  {
    return 1;
  }

  return !1;
}

sub CreatePageBase
{
  return WineTestBot::CGI::PageBase->new(@_);
}

1;
