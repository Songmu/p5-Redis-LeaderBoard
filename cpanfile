requires 'perl', '5.008001';
requires 'Mouse';
requires 'Redis';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'Test::RedisServer';
};
