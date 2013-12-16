#!/usr/bin/perl
use warnings;
use strict;
use File::Basename qw(dirname basename fileparse);
use File::Spec;
use File::Copy;
use File::Path;

my $root = "";
my $nant = "";
my $mdSource = "";
my $mdRoot = "";

main();

sub main {
	get_root();
	#prepare_sources();
	build_monodevelop();
	#die;
	#build_debugger();
	#build_monodevelop_hg();
	#finalize_monodevelop();
	#build_boo();
	#build_boo_extensions();
	#build_unityscript();
	#build_boo_md_addins(); 
	#package_monodevelop();
}

sub get_root {
	$root = File::Spec->rel2abs( dirname($0) );
	chdir $root;
	$root = File::Spec->rel2abs( File::Spec->updir() );

	$mdSource = "$root/monodevelop/main/build";
	$mdRoot = "$root/tmp/monodevelop";
	$nant = "mono --runtime=v4.0.30319 $root/monodevelop_buildtools/dependencies/nant/bin/NAnt.exe"
}

sub prepare_sources {
	if (!$ENV{UNITY_THISISABUILDMACHINE})
	{	
		printf ("Detected that this is not a build machine.\n");
		#printf ("Pulling latest MonoDevelop . . .\n");
		#chdir "$root/monodevelop";
		#system ("git pull") && die ("failed to update monodevelop");
		printf ("Pulling latest MonoDevelop.Debugger.Soft.Unity . . .\n");
		chdir "$root/MonoDevelop.Debugger.Soft.Unity";
		system ("git pull") && die ("failed to update MonoDevelop.Debugger.Soft.Unity");
		printf ("Pulling latest boo . . .\n");
		chdir "$root/boo";
		system ("git pull") && die ("failed to update boo");
		printf ("Pulling latest unityscript . . .\n");
		chdir "$root/unityscript";
		system ("git pull") && die ("failed to update unityscript");
		printf ("Pulling laest boo-md-addins . . .\n");
		chdir "$root/boo-md-addins";
		system ("git pull") && die ("failed to update boo-md-addins");
		# chdir "$root/monodevelop-hg";
		# system ("hg pull --update") && die ("failed to update monodevelop-hg");
	}
	chdir $root;

	# Check sources
	die ("Must grab Unity MonoDevelop Soft Debugger source from github first") if !-d "MonoDevelop.Debugger.Soft.Unity";
	# die ("Must grab monodevelop-hg source from bitbucket first") if !-d "monodevelop-hg";
	die ("Must grab Boo implementation") if !-d "boo";
	die ("Must grab Boo extensions") if !-d "boo-extensions";
	die ("Must grab Boo MD addins implementation") if !-d "boo-md-addins";
	die ("Must grab Unityscript implementation") if !-d "unityscript";
}

sub build_monodevelop {
	chdir "$root/monodevelop";
#	system("./configure --profile=mac");
#	system("make") && die("Failed building MonoDevelop");

	rmtree("main/build/Addins/MonoDevelop.AspNet");
	rmtree("main/build/Addins/MonoDevelop.Autotools");
	rmtree("main/build/Addins/MonoDevelop.AspNet.Mvc");
	rmtree("main/build/Addins/MonoDevelop.Deployment");
	rmtree("main/build/Addins/MonoDevelop.WebReference*");
	rmtree("main/build/Addins/MonoDeveloperExtensions");
	rmtree("main/build/Addins/DisplayBindings/Gettext");
	rmtree("main/build/Addins/MonoDevelop.RegexToolkit");
	rmtree("main/build/Addins/MonoDevelop.TextTemplating");
	rmtree("main/build/Addins/MonoDevelop.WebReferences");
	rmtree("main/build/Addins/MonoDevelop.XmlEditor");
	rmtree("main/build/Addins/MonoDevelop.RegexToolkit");
	rmtree("main/build/Addins/MonoDevelop.GtkCore");
	rmtree("main/build/Addins/VersionControl");
	system("rm main/build/Addins/BackendBindings/MonoDevelop.VBNetBinding.*");
	system("rm main/build/Addins/BackendBindings/MonoDevelop.CSharpBinding.Autotools*");
	system("rm main/build/Addins/BackendBindings/MonoDevelop.CSharpBinding.AspNet*");
	
	rmtree("main/build/Addins/MonoMac.*");


	my $brandingTarget = "main/build/bin/branding";
	mkpath($brandingTarget);
	system("rsync -av \"$root/monodevelop_buildtools/branding/\" \"$brandingTarget\"");
}

sub build_debugger {
	chdir "$root/MonoDevelop.Debugger.Soft.Unity";
	system("xbuild /property:Configuration=Release /t:Rebuild") && die("Failed building Unity debugger addin");
}

sub build_monodevelop_hg {
	chdir "$root/monodevelop-hg/monodevelop-hg";
	system("xbuild /property:Configuration=Release /t:Rebuild") && die("Failed building monodevelop-hg");
}

sub finalize_monodevelop {
	chdir $root;
	rmtree "tmp";
	mkpath "tmp";
	# TODO: First, we assembled the final monodevelop product in tmp/monodevelop, but now, currently (maybe temporarily) we need to build monodevelop, send the build folder to a mac and package it there, so the monodevelop dir needs all the bits in place before sending (can't be assembled in another folder)
	system("ln -s ../monodevelop/main/build tmp/monodevelop");

	# Unity soft debugger
	mkpath "$mdRoot/AddIns/MonoDevelop.Debugger.Soft.Unity";
	copy "$root/MonoDevelop.Debugger.Soft.Unity/obj/Release/MonoDevelop.Debugger.Soft.Unity.dll", "$mdRoot/AddIns/MonoDevelop.Debugger.Soft.Unity" or die ("Failed to copy MonoDevelop.Debugger.Soft.Unity");	
	copy "$root/MonoDevelop.Debugger.Soft.Unity/obj/Release/MonoDevelop.Debugger.Soft.Unity.dll.mdb", "$mdRoot/AddIns/MonoDevelop.Debugger.Soft.Unity" or die ("Failed to copy MonoDevelop.Debugger.Soft.Unity");	
	
	# Unity utilities
	copy "$root/MonoDevelop.Debugger.Soft.Unity/obj/Release/UnityUtilities.dll", "$mdRoot/AddIns" or die ("Failed to copy UnityUtilities");	
	# monodevelop-hg
	# copy "$root/monodevelop-hg/monodevelop-hg/bin/Release/MonoDevelop.VersionControl.Mercurial.dll", "$mdRoot/AddIns/VersionControl" or die ("Failed to copy monodevelop-hg");	
	# copy "$root/monodevelop-hg/monodevelop-hg/bin/Release/Mercurial.dll", "$mdRoot/AddIns/VersionControl" or die ("Failed to copy monodevelop-hg");	

	chdir "$root/monodevelop/main/build/MacOSX";
	system("make app") && die("Failed running make app for MonoDevelop");
}

sub build_boo {
	chdir "$root/boo";
	system("$nant rebuild") && die ("Failed to build Boo");
	mkpath "$mdRoot/AddIns/BackendBindings/Boo/boo";
	system("rsync -av \"$root/boo/build/\" \"$mdRoot/AddIns/BackendBindings/Boo/boo\"");
}

sub build_boo_extensions {
	chdir "$root/boo-extensions";
	copy "$root/monodevelop_buildtools/dependencies/build.properties", "$root/boo-extensions/build.properties";
	system("$nant rebuild") && die ("Failed to build Boo");
}

sub build_unityscript {
	chdir "$root/unityscript";
	my $javascriptFiles =  "$mdRoot/AddIns/BackendBindings/UnityScript/bin";
	mkpath $javascriptFiles;
	rmtree "$root/unityscript/bin";
	system("$nant rebuild") && die ("Failed to build UnityScript");
	system("rsync -av --exclude=*Tests* --exclude=nunit* \"$root/unityscript/bin/\" \"$javascriptFiles\"");
}

sub build_boo_md_addins {
	chdir "$root/boo-md-addins";
	copy "$root/monodevelop_buildtools/dependencies/build.properties", "$root/boo-md-addins/build.properties";
	system("$nant rebuild") && die ("Failed to build Boo-based addins");
	copy "$root/boo-md-addins/build/Boo.MonoDevelop.dll", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/Boo.MonoDevelop.dll.mdb", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/Boo.Ide.dll", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/Boo.Ide.dll.mdb", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/UnityScript.Ide.dll", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/UnityScript.Ide.dll.mdb", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/Boo.MonoDevelop.Util.dll", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/Boo.MonoDevelop.Util.dll.mdb", "$mdRoot/AddIns/BackendBindings/Boo";
	copy "$root/boo-md-addins/build/UnityScript.MonoDevelop.dll", "$mdRoot/AddIns/BackendBindings/UnityScript";
	copy "$root/boo-md-addins/build/UnityScript.Ide.dll", "$mdRoot/AddIns/BackendBindings/UnityScript";
	copy "$root/boo-md-addins/build/Boo.Ide.dll", "$mdRoot/AddIns/BackendBindings/UnityScript";
	copy "$root/boo-md-addins/build/Boo.MonoDevelop.Util.dll", "$mdRoot/AddIns/BackendBindings/UnityScript";
}

sub package_monodevelop {
	system("cp -R $mdRoot/* $root/monodevelop/main/build");
	chdir "$root/monodevelop";
	print "Collecting built files so they can be packaged on a mac\n";
	unlink "MonoDevelop.tar.gz";
	system("tar cfz MonoDevelop.tar.gz main extras");
	move "MonoDevelop.tar.gz", "$root";
	chdir "$root";
}
