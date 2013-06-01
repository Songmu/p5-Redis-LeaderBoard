package Redis::Ranking;
use 5.008001;
our $VERSION = "0.01";
use Mouse;
use Mouse::Util::TypeConstraints;

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has redis => (
    is       => 'ro',
    isa      => 'Redis',
    required => 1,
);

enum 'Redis::Ranking::Order' => qw/asc desc/;
has order => (
    is      => 'ro',
    isa     => 'Redis::Ranking::Order',
    default => 'asc',
);

no Mouse;

# consider bulk?
sub set_score {
    my ($self, $member, $score) = @_;
    $self->redis->zadd($self->key, $score, $member);
}

sub get_score {
    my ($self, $member) = @_;
    $self->redis->zscore($self->key, $member);
}

sub incr_score {
    my ($self, $member, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->redis->zincrby($self->key, $score, $member);
}

sub decr_score {
    my ($self, $member, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->redis->zincrby($self->key, -$score, $member);
}

# consider bulk?
sub remove {
    my ($self, $member) = @_;

    $self->redis->zrem($self->key, $member);
}

sub get_rank_with_score {
    my ($self, $member) = @_;
    my $redis = $self->redis;

    my $score = $self->get_score($member);
    return unless defined $score; # should throw exception?

    my $method = $self->order eq 'asc' ? 'zrevrank' : 'zrank';
    my $rank  = $redis->$method($self->key, $member);

    return ($rank + 1, $score) if $rank == 0; # zero origin

    my $above_member;
    if ($self->order eq 'asc') {
        $above_member = @{$redis->zrangebyscore($self->key, "($score", 'inf', 'limit', 0, 1) || []}[0];
    }
    else {
        $above_member = @{$redis->zrevrangebyscore($self->key, "($score", '-inf', 'limit', 0, 1) || []}[0];
    }

    if ($above_member) {
        $rank = $redis->$method($self->key, $above_member) + 2;
    }
    else {
        $rank = 1;
    }

    ($rank, $score);
}

sub get_rank {
    my ($self, $member) = @_;

    my ($rank) = $self->get_rank_with_score($member);
    $rank;
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::Ranking - It's new $module

=head1 SYNOPSIS

    use Redis::Ranking;

=head1 DESCRIPTION

Redis::Ranking is ...

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

