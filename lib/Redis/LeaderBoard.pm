package Redis::LeaderBoard;
use 5.008001;
our $VERSION = "0.01";
use Mouse;
use Mouse::Util::TypeConstraints;
use Redis::LeaderBoard::Member;

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has redis => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

enum 'Redis::LeaderBoard::Order' => qw/asc desc/;
has order => (
    is      => 'ro',
    isa     => 'Redis::LeaderBoard::Order',
    default => 'asc',
);

has is_asc => (
    is   => 'ro',
    isa  => 'Bool',
    lazy => 1,
    default => sub { shift->order eq 'asc' },
);

no Mouse;

sub find_member {
    my ($self, $member) = @_;

    Redis::LeaderBoard::Member->new(
        id           => $member,
        leader_board => $self,
    );
}

sub set_score {
    my ($self, @member_and_scores) = @_;
    @member_and_scores = reverse @member_and_scores;
    $self->redis->zadd($self->key, @member_and_scores);
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

sub remove {
    my ($self, @members) = @_;

    $self->redis->zrem($self->key, @members);
}

sub get_sorted_order {
    my ($self, $member) = @_;

    my $method = $self->is_asc ? 'zrevrank' : 'zrank';
    $self->redis->$method($self->key, $member);
}

sub get_rank_with_score {
    my ($self, $member) = @_;
    my $redis = $self->redis;

    my $score = $self->get_score($member);
    return unless defined $score;

    my $method = $self->is_asc ? 'zrevrank' : 'zrank';
    my $rank  = $self->get_sorted_order($member);

    return (1, $score) if $rank == 0; # zero origin

    my ($min, $max) = $self->is_asc ? ("($score", 'inf') : ('-inf', "($score");
    my $above_count = $redis->zcount($self->key, $min, $max);
    $rank = $above_count + 1;

    ($rank, $score);
}

sub get_rank {
    my ($self, $member) = @_;

    my ($rank) = $self->get_rank_with_score($member);
    $rank;
}

sub rankings {
    my ($self, %args) = @_;
    my $limit  = exists $args{limit}  ? $args{limit}  : $self->member_count;
    my $offset = exists $args{offset} ? $args{offset} : 0;

    my $range_method = $self->is_asc ? 'zrevrange' : 'zrange';

    my $members = $self->redis->$range_method($self->key, $offset, $offset + $limit - 1);
    my @rankings;
    # needs pipelie?
    for my $member (@$members) {
        my ($rank, $score) = $self->get_rank_with_score($member);

        push @rankings, +{
            member => $member,
            score  => $score,
            rank   => $rank,
        };
    }
    \@rankings;
}

sub member_count {
    my $self = shift;
    $self->redis->zcard($self->key);
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::LeaderBoard - It's new $module

=head1 SYNOPSIS

    use Redis::LeaderBoard;

=head1 DESCRIPTION

Redis::LeaderBoard is ...

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

