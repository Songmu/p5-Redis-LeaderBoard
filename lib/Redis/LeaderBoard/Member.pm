package Redis::LeaderBoard::Member;
use Mouse;

has leader_board => (
    is       => 'ro',
    isa      => 'Redis::LeaderBoard',
    required => 1,
);

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Mouse;

sub score {
    my ($self, $score) = @_;

    return $self->leader_board->get_score($self->id) unless $score;

    $self->leader_board->set_score($self->id, $score);
    $score;
}

sub incr {
    my ($self, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->leader_board->incr_score($self->id, $score);
}

sub decr {
    my ($self, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->leader_board->decr_score($self->id, $score);
}

sub rank_with_score {
    my $self = shift;
    $self->leader_board->get_rank_with_score($self->id);
}

sub rank {
    my $self = shift;
    $self->leader_board->get_rank($self->id);
}

sub sorted_order {
    my $self = shift;

    $self->leader_board->sorted_order($self->id);
}

1;
