use Tkx;
use Encode;
use Encode::CN;
use Encode::Alias;
use Encode::MIME::Name;
use Locale::Codes::Language_Codes;
use Compress::Zlib;
use Exporter;
use Font::Subsetter;
use Font::TTF::AATKern;
use Font::TTF::AATutils;
use Font::TTF::Anchor;
use Font::TTF::Bsln;
use Font::TTF::Cmap;
use Font::TTF::Coverage;
use Font::TTF::Cvt_;
use Font::TTF::Delta;
use Font::TTF::Dumper;
use Font::TTF::EBDT;
use Font::TTF::EBLC;
use Font::TTF::Fdsc;
use Font::TTF::Feat;
use Font::TTF::Fmtx;
use Font::TTF::Font;
use Font::TTF::Fpgm;
use Font::TTF::GDEF;
use Font::TTF::GPOS;
use Font::TTF::GPOS;
use Font::TTF::GSUB;
use Font::TTF::Glyf;
use Font::TTF::Glyph;
use Font::TTF::GrFeat;
use Font::TTF::Hdmx;
use Font::TTF::Head;
use Font::TTF::Hhea;
use Font::TTF::Hmtx;
use Font::TTF::Kern;
use Font::TTF::Kern::ClassArray;
use Font::TTF::Kern::CompactClassArray;
use Font::TTF::LTSH;
use Font::TTF::Loca;
use Font::TTF::Maxp;
use Font::TTF::Kern::OrderedList;
use Font::TTF::Kern::StateTable;
use Font::TTF::Mort;
use Font::TTF::Mort::Contextual;
use Font::TTF::Mort::Insertion;
use Font::TTF::Mort::Ligature;
use Font::TTF::Name;
use Font::TTF::Mort::Noncontextual;
use Font::TTF::OS_2;
use Font::TTF::OTTags;
use Font::TTF::OldCmap;
use Font::TTF::OldMort;
use Font::TTF::PCLT;
use Font::TTF::PSNames;
use Font::TTF::Post;
use Font::TTF::Prep;
use Font::TTF::Prop;
use Font::TTF::Mort::Rearrangement;
use Font::TTF::Segarr;
use Font::TTF::Sill;
use Font::TTF::Table;
use Font::TTF::Ttc;
use Font::TTF::Ttopen;
use Font::TTF::Useall;
use Font::TTF::Utils;
use Font::TTF::Vhea;
use Font::TTF::Vmtx;
use Font::TTF::OS_2;
use Font::TTF::Segarr;
use Font::TTF::Table;
use Font::TTF::Win32;
use Font::TTF::XMLparse;
use Font::TTF;
use Getopt::Long;
use Cwd; 
my $curPath = getcwd();

my $mainWin = Tkx::widget->new(".");
$mainWin->g_wm_title("Font slim");
$mainWin->g_wm_minsize(500,300);

my $frame = $mainWin->new_ttk__frame(-padding => "3 3 3 3");
$frame->g_grid(-column => 0, -row => 0, -sticky => "nwes");
$mainWin->g_grid_columnconfigure(0, -weight => 1);
$mainWin->g_grid_rowconfigure(0, -weight => 1);

my $input;
my $output;
my $pathValue = "Select ttf file!";
my $openBtn = $frame->new_ttk__button(-text=> "Browse",-command=>\&openBrowse );
$openBtn->g_grid(-column => 1, -row => 1, -sticky => "w");
my $path = $frame->new_ttk__label(-textvariable => \$pathValue);
$path->g_grid(-column=>1,-row=>1);

my $runBtn = $frame->new_ttk__button(-text=> "Run",-command=> \&run );
$runBtn->g_grid(-column => 1, -row => 1,-sticky=>"e");
my $inputbox = $frame->new_tk__text(-width => 70, -height => 20);
$inputbox->g_grid(-column => 1,-row=>2);
$inputbox->see('end');
Tkx::MainLoop;
sub run{
	my $str = $inputbox->get('1.0','end-1c');
	if($str =~ /^\s*$/){
		message("Content can not be empty!");
	}else{
		if(-f $pathValue){
			$str = encode("gbk",$str);
			main($pathValue,"output.ttf",$str);
			message("Done!\nOutput file is in $curPath/output.ttf");
		}else{
			message("Input file not found!")
		}
	}
}
sub message{
	my $content = shift;
	Tkx::tk___messageBox(
		 -parent=>$mainWin,
		 -icon => "info",
		 -title => "Info",
		 -message => $content);
}
sub openBrowse{
	my $temp = Tkx::tk___getOpenFile();
	if($temp !~ /^\s*$/&&$temp !~ /\.ttf$/){
		message("Only ttf file!");
	}else{
		$pathValue = $temp;
	}
}
sub main {
    my $input_file = shift;
	my $output_file = shift;
	my $chars = shift;
    my $verbose = 0;
    my $charsfile;
    my $include;
    my $exclude;
    my $apply;
    my $license_desc_subst;

    my $result = GetOptions(
        'chars=s' => \$chars,
        'charsfile=s' => \$charsfile,
        'verbose' => \$verbose,
        'include=s' => \$include,
        'exclude=s' => \$exclude,
        'apply=s' => \$apply,
        'licensesubst=s' => \$license_desc_subst,
    ) or help();



    if ($verbose) {
        dump_sizes($input_file);
        print "Generating subsetted font...\n\n";
    }

    my $features;
    if ($include) {
        $features = { DEFAULT => 0 };
        $features->{$_} = 1 for split /,/, $include;
    } elsif ($exclude) {
        $features = { DEFAULT => 1 };
        $features->{$_} = 0 for split /,/, $exclude;
    }

    my $fold_features;
    if ($apply) {
        $fold_features = [ split /,/, $apply ];
    }

    my $subsetter = new Font::Subsetter();
    $subsetter->subset($input_file, $chars, {
        features => $features,
        fold_features => $fold_features,
        license_desc_subst => $license_desc_subst,
    });
    $subsetter->write($output_file);

    if ($verbose) {
        print "\n";
        print "Features:\n  ";
        print join ' ', $subsetter->feature_status();
        print "\n\n";
        print "Included glyphs:\n  ";
        print join ' ', $subsetter->glyph_names();
        print "\n\n";
        dump_sizes($output_file);
    }

    $subsetter->release();
}

sub dump_sizes {
    my ($filename) = @_;
    my $font = Font::TTF::Font->open($filename) or die "Failed to open $filename: $!";
    print "TTF table sizes:\n";
    my $s = 0;
    for (sort keys %$font) {
        next if /^ /;
        my $l = $font->{$_}{' LENGTH'};
        $s += $l;
        print "  $_: $l\n";
    }
    print "Total size: $s bytes\n\n";
    $font->release();
}
