package LastFM::Export;
use Moose;
# ABSTRACT: data exporter for last.fm

use Data::Stream::Bulk::Callback;
use Net::LastFM;

with 'MooseX::Getopt';

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has api_key => (
    is       => 'ro',
    isa      => 'Str',
    default  => '30b55f2e2e78056b16dbb15cb0899c2d',
);

has lastfm => (
    is      => 'ro',
    isa     => 'Net::LastFM',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Net::LastFM->new(
            api_key    => $self->api_key,
            api_secret => '',
        );
    },
);

sub track_count {
    my $self = shift;
    my (%params) = @_;

    $params{method} = 'user.getRecentTracks';
    $params{user}   = $self->user;
    $params{limit}  = 1;

    return $self->lastfm->request(%params)->{recenttracks}{'@attr'}{total};
}

sub tracks {
    my $self = shift;
    my (%params) = @_;

    $params{method}   = 'user.getRecentTracks';
    $params{user}     = $self->user;
    $params{limit}  ||= 200;
    $params{page}   ||= 1;

    return Data::Stream::Bulk::Callback->new(
        callback => sub {
            my $data = $self->lastfm->request(%params);

            return if $params{page} > $data->{recenttracks}{'@attr'}{totalPages};
            $params{page}++;

            return $data->{recenttracks}{track};
        },
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
