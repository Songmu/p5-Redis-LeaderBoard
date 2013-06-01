use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::RedisServer;
use Redis;
use Redis::Ranking;

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new($redis_server->connect_info);

my $redis_ranking = Redis::Ranking->new(
    key   => 'ranking',
    redis => $redis,
);

subtest 'get incr set' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test1',
        redis => $redis,
    );

    $redis_ranking->set_score(one => 10);
    is $redis_ranking->incr_score(one => 10), 20;
    is $redis_ranking->get_score('one'), 20;

    is $redis_ranking->decr_score(one => 3), 17;
    is $redis_ranking->get_score('one'), 17;

    $redis_ranking->set_score(one => 5);
    is $redis_ranking->get_score('one'), 5;
};

subtest 'empty' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'empty',
        redis => $redis,
    );
    my ($rank, $score) = $redis_ranking->get_rank_with_score('one');
    ok !$rank;
    ok !$score;
    ok !$redis_ranking->get_score('one');
    ok !$redis_ranking->get_rank('one');
};

subtest 'get_rank_with_score' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test_asc',
        redis => $redis,
    );
    my @scores = (
        [1, one   => 100],
        [2, two   => 50],
        [2, two2  => 50],
        [4, four  => 30],
        [5, five  => 10],
        [6, six   => 8],
        [6, six2  => 8],
        [6, six3  => 8],
        [9, nine  => 1],
    );
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        $redis_ranking->set_score($member => $score);
    }
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        is_deeply [$redis_ranking->get_rank_with_score($member)],  [$rank, $score];
        is $redis_ranking->get_rank($member), $rank;
    }
};

subtest 'get_rank_with_score_desc' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test_desc',
        redis => $redis,
        order => 'desc',
    );
    my @scores = (
        [1, one   => -11],
        [2, two   => 11],
        [2, two2  => 11],
        [4, four  => 20],
        [5, five  => 30],
        [6, six   => 44],
        [6, six2  => 44],
        [6, six3  => 44],
        [9, nine  => 80],
    );
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        $redis_ranking->set_score($member => $score);
    }
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        is_deeply [$redis_ranking->get_rank_with_score($member)],  [$rank, $score];
        is $redis_ranking->get_rank($member), $rank;
    }
};

subtest 'get_rank_with_score_same' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test_same1',
        redis => $redis,
    );
    my @scores = (
        [1, one   => 100],
        [1, one2  => 100],
        [3, three => 50],
    );
    for my $score (@scores) {
        my ($rank, $member, $score) = @$score;
        $redis_ranking->set_score($member => $score);
    }

    is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 100];
    is_deeply [$redis_ranking->get_rank_with_score('one2')], [1, 100];
    is_deeply [$redis_ranking->get_rank_with_score('three')], [3, 50];

    $redis_ranking->incr_score(one => 1);
    is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 101];
    is_deeply [$redis_ranking->get_rank_with_score('one2')], [2, 100];

    $redis_ranking->remove('one2');
    is_deeply [$redis_ranking->get_rank_with_score('three')], [2, 50];
};

done_testing;
