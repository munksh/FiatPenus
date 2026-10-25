Name:       harbour-fiatpenus
Summary:    fiat penus – household lists, notes and photos
Version:    1.0
Release:    1
License:    MIT
URL:        https://github.com/munksh/FiatPenus
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  desktop-file-utils

%description
A household's lists, notes wall and photo board: checklists with
categories, quantities and repeats, notes in Markdown, photos in folders.
The phone has a household of its own that needs no account; connect a
Nextcloud with Pantry on it and its households come alongside, shared with
everyone in them and kept on your own server.

%if 0%{?_chum}
Title: fiat penus - pantry client
Type: desktop-application
DeveloperName: Munkstolen
Categories:
 - Utility
 - Office
AIRating: V
AINote: Claude is my typist - I cross review with Mistral, and add the code once it looks good. Architecture, design, on-device testing, releases and maintenance by me; issues and input welcome.
PackageIcon: https://munkstolen.se/SFOS/harbour-fiatpenus.png
Screenshots:
 - https://munkstolen.se/SFOS/fiatpenus1.png
 - https://munkstolen.se/SFOS/fiatpenus2.png
 - https://munkstolen.se/SFOS/fiatpenus3.png
 - https://munkstolen.se/SFOS/fiatpenus4.png
 - https://munkstolen.se/SFOS/fiatpenus5.png
Custom:
  Repo: https://github.com/munksh/FiatPenus
Links:
  Homepage: https://github.com/munksh/FiatPenus
  Bugtracker: https://github.com/munksh/FiatPenus/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 APP_VERSION=%{version}
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install INSTALL_ROOT=%{buildroot}

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Wed Oct 21 2026 Caesar Prometheus Ivarsson <caesar@munkstolen.se> - 1.0-1
- A household on the phone itself: lists, notes and photos with no account.
- One front page with three sides, Lists, Notes and Photos, and the
  households as words under the card.
- The card shows what is left to fix, the notes on the wall, the photos on
  the board.
- Pull down to refresh, with a spinner until it is done.
* Mon Oct 19 2026 Caesar Prometheus Ivarsson <caesar@munkstolen.se> - 0.1-1
- First test build: sign-in, households, lists, notes and photos.
