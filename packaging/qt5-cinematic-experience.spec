Name:           qt5-cinematic-experience
Version:        1.0
Release:        0
License:        Multiple/CC-BY-3.0,...
Summary:        UX demo application using Qt5
Url:            http://quitcoding.com/?page=work
Group:          System/Libraries
Source:         %{name}_%{version}.orig.tar.gz

BuildRequires:  make
BuildRequires:  qt5-qmake
BuildRequires:  fdupes
BuildRequires:  qt5-qtdeclarative-qtquick-devel
Requires:       qt5-qtdeclarative-import-qtquick2plugin
Requires:       qt5-qtdeclarative-import-particles2
Requires:       qt5-qtgraphicaleffects

%description

This UX demo application presents some graphical features of Qt5.
The name 'Cinematic Experience' reflects how it's possible to build user
interfaces with increased dynamics.


%prep
%setup -q
export QTDIR=/usr/share/qt5
touch .git # To make sure syncqt is used

%qmake5 CONFIG+=package


%build
%__make %{?_smp_mflags} V=1

%install
%make_install
%fdupes %{buildroot}

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files
%defattr(-,root,root)
/opt/Qt5_CinematicExperience/*
