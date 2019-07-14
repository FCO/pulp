use Pulp::EventType;

class Pulp::Event {
    has Pulp::EventType $.type;
    has Instant         $.when = now;
    has Str             $.task is required;
    has                 $.data
}

