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
    my %score = (
        one   => 100,
        two   => 50,
        two2  => 50,
        four  => 30,
        five  => 10,
        six   => 8,
        six2  => 8,
        six3  => 8,
        nine  => 1,
    );
    for my $member (keys %score) {
        $redis_ranking->set_score($member => $score{$member});
    }

    subtest get_rank_with_score => sub {
        is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 100];
        is_deeply [$redis_ranking->get_rank_with_score('two')],  [2, 50];
        is_deeply [$redis_ranking->get_rank_with_score('two2')], [2, 50];
        is_deeply [$redis_ranking->get_rank_with_score('four')], [4, 30];
        is_deeply [$redis_ranking->get_rank_with_score('five')], [5, 10];
        is_deeply [$redis_ranking->get_rank_with_score('six')],  [6, 8];
        is_deeply [$redis_ranking->get_rank_with_score('six2')], [6, 8];
        is_deeply [$redis_ranking->get_rank_with_score('six3')], [6, 8];
        is_deeply [$redis_ranking->get_rank_with_score('nine')], [9, 1];

        is $redis_ranking->get_rank('five'), 5;
    };
};

subtest 'get_rank_with_score_desc' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test_desc',
        redis => $redis,
        order => 'desc',
    );
    my %score = (
        one   => -11,
        two   => 11,
        two2  => 11,
        four  => 20,
        five  => 30,
        six   => 44,
        six2  => 44,
        six3  => 44,
        nine  => 80,
    );
    for my $member (keys %score) {
        $redis_ranking->set_score($member => $score{$member});
    }

    subtest get_rank_with_score => sub {
        is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, -11];
        is_deeply [$redis_ranking->get_rank_with_score('two')],  [2, 11];
        is_deeply [$redis_ranking->get_rank_with_score('two2')], [2, 11];
        is_deeply [$redis_ranking->get_rank_with_score('four')], [4, 20];
        is_deeply [$redis_ranking->get_rank_with_score('five')], [5, 30];
        is_deeply [$redis_ranking->get_rank_with_score('six')],  [6, 44];
        is_deeply [$redis_ranking->get_rank_with_score('six2')], [6, 44];
        is_deeply [$redis_ranking->get_rank_with_score('six3')], [6, 44];
        is_deeply [$redis_ranking->get_rank_with_score('nine')], [9, 80];

        is $redis_ranking->get_rank('five'), 5;
    };
};

subtest 'get_rank_with_score_same' => sub {
    my $redis_ranking = Redis::Ranking->new(
        key   => 'test_same1',
        redis => $redis,
    );
    my %score = (
        one   => 100,
        one2  => 100,
        three => 50,
    );
    for my $member (keys %score) {
        $redis_ranking->set_score($member => $score{$member});
    }

    subtest get_rank_with_score => sub {
        is_deeply [$redis_ranking->get_rank_with_score('one')],  [1, 100];
        is_deeply [$redis_ranking->get_rank_with_score('one2')], [1, 100];
        is_deeply [$redis_ranking->get_rank_with_score('three')], [3, 50];
    };
};


done_testing;
