use Pulp::File;

my &minify;
{
    use JS::Minify;
    &minify = &js-minify;
}

sub js-minify(*%opts) is export {
    -> Pulp::File $file {
        $file.clone: :content($file.content.reduce(* ~ *).map: -> $data { minify :input($data), |%opts })
    }
}
