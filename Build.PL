
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Evaluate code",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Pod-Weaver-Plugin-Eval",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Pod::Weaver::Plugin::Eval",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Pod::Weaver" => 0,
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
