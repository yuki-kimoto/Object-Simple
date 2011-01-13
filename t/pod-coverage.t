use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

{
    all_pod_coverage_ok({also_private => [qw/^(build_all_classes|unimport|attr|class_attr|hybrid_attr|class_attrs|inherit_prototype|create_accessor|create_class_accessor|create_dual_accessor|dual_attr|delete_class_attr|exists_class_attr|create_accessors|create_attr_accessor|inherit_attribute)$/]});
}

