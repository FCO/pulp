use Pulp::File;

sub subst($regex, $sub, *%flags) is export {
    -> Pulp::File $file {
        $file.clone: :content($file.content.map: *.subst: $regex, $sub, |%flags)
    }
}
