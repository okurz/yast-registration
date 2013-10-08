#
# spec file for package yast2-registration
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-registration
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
Requires:       yast2 >= 2.23.13
Requires:       yast2-packager >= 2.17.0
Requires:       suseRegister
Requires:       perl-camgm perl-TimeDate
Requires:       yast2-pkg-bindings >= 2.17.20
Requires:       yast2-registration-branding
Requires:       yast2-ruby-bindings >= 1.0.0
Requires(post): sed grep
PreReq:         %fillup_prereq
BuildRequires:  yast2 >= 2.23.13
BuildRequires:  update-desktop-files
BuildRequires:  yast2-devtools >= 3.0.6
Buildrequires:  polkit
BuildArch:      noarch
Summary:        YaST2 - Registration Module

Source1:        org.opensuse.yast.modules.ysr.policy
%description
The registration module to register products and/or to fetch an update
source (mirror) automatically.


Authors:
--------
    J. Daniel Schmidt <jdsn@suse.de>

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

mkdir -p $RPM_BUILD_ROOT/usr/share/polkit-1/actions
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/polkit-1/actions


%package branding-SLE
License:        GPL-2.0
Requires:       yast2-registration
Provides:       yast2-registration-branding
Conflicts:      otherproviders(yast2-registration-branding)
Summary:        YaST2 - Registration Module
Group:          System/YaST

%description branding-SLE
The registration module to register products and/or to fetch an update
source (mirror) automatically.


Authors:
--------
    J. Daniel Schmidt <jdsn@suse.de>

%package branding-openSUSE
License:        GPL-2.0
Requires:       yast2-registration
Provides:       yast2-registration-branding
Conflicts:      otherproviders(yast2-registration-branding)
Summary:        YaST2 - Registration Module
Group:          System/YaST

%description branding-openSUSE
The registration module to register products and/or to fetch an update
source (mirror) automatically.


Authors:
--------
    J. Daniel Schmidt <jdsn@suse.de>


%pre
/usr/sbin/groupadd -r suse-ncc 2> /dev/null || :
/usr/sbin/useradd -r -s /bin/bash -c "Novell Customer Center User" -d /var/lib/YaST2/suse-ncc-fakehome -g suse-ncc suse-ncc 2> /dev/null || :

%post
%{fillup_only -ns suse_register yast2-registration}
# fix broken xauth export from previous registration (bnc#702638)
export XAEXPORT=/root/.xauth/export
if [ -e "$XAEXPORT" ] && grep -q -v "^\s*$" "$XAEXPORT"
then
  sed -i --follow-symlinks "/^suse-ncc$/d" "$XAEXPORT"
  grep -q -v "^\s*$" "$XAEXPORT" || rm -f "$XAEXPORT"
fi


%files
%defattr(-,root,root)
%doc %{yast_docdir}
%{yast_clientdir}/*.rb
%{yast_moduledir}/*.pm
%{yast_moduledir}/*.rb
%dir %{yast_yncludedir}/registration
%{yast_yncludedir}/registration/*.rb
%{yast_schemadir}/autoyast/rnc/*.rnc
/usr/share/YaST2/yastbrowser
# agents
%{yast_scrconfdir}/cfg_suse_register.scr
#fillup
/var/adm/fillup-templates/sysconfig.suse_register-yast2-registration
%attr(644,root,root) %config /usr/share/polkit-1/actions/org.opensuse.yast.modules.*.policy

%files branding-SLE
%defattr(-,root,root)
%{yast_desktopdir}/customer_center.desktop

%files branding-openSUSE
%defattr(-,root,root)
%{yast_desktopdir}/suse_register.desktop
%changelog