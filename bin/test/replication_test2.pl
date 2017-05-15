#!/usr/bin/perl

# Note: Test replication scheduler

use strict;
use warnings;
use JSON;

use lib ('.', '../..');

use Data::Dumper;

use Test::MockModule;
use ReplicationTestEnv;
use Test::More tests => 1;

$ReplicationTestEnv::mocked_nodename = 'node1';

my $schedule = [];

my $mocked_replicate = sub {
    my ($jobcfg, $start_time) = @_;

    push @$schedule, {
	id => $jobcfg->{id},
	guest => $jobcfg->{guest},
	vmtype => $jobcfg->{vmtype},
	start => $start_time,
    };
};

my $pve_replication_module = Test::MockModule->new('PVE::Replication');
$pve_replication_module->mock(replicate => $mocked_replicate);


my $testjob = {
    'type'  => 'local',
    'target' => 'node1',
    'guest' => 900,
};

$ReplicationTestEnv::mocked_replication_jobs = {
    job_900_to_node2 => {
	'type'  => 'local',
	'target' => 'node2',
	'guest' => 900,
    },
    job_900_to_node1 => {
	'type'  => 'local',
	'target' => 'node1', # local node, job should be skipped
	'guest' => 900,
    },
};

$ReplicationTestEnv::mocked_vm_configs = {
    900 => {
	node => 'node1',
	snapshots => {},
	ide0 => 'local-lvm:vm-900-disk-1,size=4G',
	memory => 512,
	ide2 => 'none,media=cdrom',
    },
};

ReplicationTestEnv::setup();

for (my $i = 0; $i < 61; $i++) {
    PVE::Replication::run_jobs($i*60);
}

#print Dumper($schedule);

my $exptected_schedule = [
    {
	'start' => 0,
	'vmtype' => 'qemu',
	'id' => 'job_900_to_node2',
	'guest' => 900
    },
    {
	'guest' => 900,
	'id' => 'job_900_to_node2',
	'vmtype' => 'qemu',
	'start' => 900
    },
    {
	'start' => 1800,
	'vmtype' => 'qemu',
	'id' => 'job_900_to_node2',
	'guest' => 900
    },
    {
	'vmtype' => 'qemu',
	'start' => 2700,
	'id' => 'job_900_to_node2',
	'guest' => 900
    }
];

is_deeply($schedule, $exptected_schedule);

exit(0);
