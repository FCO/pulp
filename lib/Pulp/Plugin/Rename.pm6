use Pulp::File;

sub rename(&trans) is export {
    -> Pulp::File $file {
        $file.clone: :path($file.path.clone: :path("{ $file.path.dirname }/{ trans $file.path.basename }"))
    }
}
