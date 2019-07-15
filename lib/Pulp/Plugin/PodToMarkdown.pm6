use Pulp::File;

sub pod-to-markdown(*@opts) is export {
    -> Pulp::File $file {
        my $proc = Proc::Async.new: :w, "perl6", "--doc=Markdown", |@opts;
        my $new-file = $file.clone: :content($proc.stdout.share);
        $proc.start;
        $file.content.do({ $proc.print: $_ }).Promise.then({ $proc.close-stdin });
        $new-file
    }
}
