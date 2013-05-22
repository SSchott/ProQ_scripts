#!/usr/bin/perl -w
use Cwd 'abs_path';
use File::Basename;
use LWP::UserAgent; 
use HTML::Parser;


if(scalar(@ARGV) % 2 != 0) {
    print STDERR "Usage: run_all_external.pl -pdb [pdbfile] -membrane 1 (if membrane protein) -overwrite 1 (if overwrite)\n";
    exit;
}
%param=@ARGV;
if(not(defined($param{-pdb}))) {
    print STDERR "Usage: run_all_external.pl -pdb [pdbfile] -membrane 1 (if membrane protein) -overwrite 1 (if overwrite)\n";
    exit;
}
my $membrane=0;
my $overwrite=0;
if(defined($param{-overwrite})) {
    $overwrite=1;
}
if(defined($param{-membrane})) {
    $membrane=1;
}

$pdb_in=$param{-pdb};

my $DB="/home/bjornw/Research/DB/uniref90.fasta";

my $INSTALL_DIR=dirname(abs_path($0));
$INSTALL_DIR.="/.."; 
#my $DB=$INSTALL_DIR."/DB/uniref90.fasta";
my $full_path=abs_path($pdb_in);
my $path=dirname($full_path);
my $pdb=basename($full_path);
chdir($path);
print "run all for $pdb in $path...\n";

#`mv -f $pdb $pdb.orig`;
#`grep ^ATOM $pdb.orig | $INSTALL_DIR/bin/kill_chain.pl  > $pdb`;
 
#fasta
$fasta="$pdb.fasta";
$seq=`$INSTALL_DIR/bin/aa321CA.pl $pdb`;
chomp($seq);
if($overwrite || !-e $fasta) {
    print "Creating fasta file..\n";
    
    open(OUT,">$fasta");
    print OUT ">$pdb\n$seq\n";
    close(OUT);
}

print $seq."\n";
$profile_file="$pdb.psi";
#
if($overwrite) {
	unlink("$pdb.psi");
	unlink("$pdb.mtx");
	unlink("$pdb.chk");
	unlink("$pdb.ss2");
}
if(!-e $profile_file) {
    print "Creating profiles and predicting ss\n";
    
   # print "/Users/bjornw/Research/bin/create_profile.sh $fasta\n";
   # `/Users/bjornw/Research/bin/create_profile.sh $fasta`;

     print "$INSTALL_DIR/bin/create_profile.sh $fasta $DB\n";
    system("$INSTALL_DIR/bin/create_profile.sh $fasta $DB");
}

if($membrane)
{
    $topcons="$pdb.topcons";
    $topcons_fa="$pdb.topcons.fa";
    if($overwrite || !-e $topcons) {
	print "topcons...\n";
	my $ua = new LWP::UserAgent;
	my $response = $ua -> post('http://topcons.net',{'sequence' => $seq,'do' => 'Submit',});
	$content=$response->content();
	if($content=~/result\/(.+)\/topcons.txt/) {
	    $id=$1;
	    print $id."\n";
	    my $response = $ua -> post("http://topcons.net/result/$id/topcons.txt");
	    open(OUT,">$topcons");
	    print OUT $response->content();
	    close(OUT);
	#my $parser = new MyParser;
#	my $parsed=$parser->parse($content);
#	print $parsed."\n";
#	$string="sequence=$seq\&do=Submit";
#	$output=`echo "$string" | lynx -post_data http://topcons.net`;
#	    exit;
#	open(OUT,">$topcons");
#	print OUT $output;
#	close(OUT);
	}
#`run_topcons.pl $fasta > $topcons`;
    }
    if($overwrite || !-e "$topcons.fa"){ 
	print "Topcons to fasta...\n";
#	`$INSTALL_DIR/bin/parse_topcons.pl $topcons > $topcons.fa`;
	my ($seq2,$topo2)=parse_topcons($topcons);
	open(TOPCONS,">$topcons.fa");
	print TOPCONS ">$topcons\n$topo2\n";
	close(TOPCONS);
    }
    my $zpred = "$INSTALL_DIR/apps/zpred/zpred.pl"; #/afs/pdc.kth.se/home/k/kriil/vol_03/Programs/zpred/bin/zpred.pl";
    $zpred_file="$pdb.zpred";
    $temp_dir="/tmp/";
    if(!-e $zpred_file) {
	print "Zpred...\n";
	print "$zpred -mode profile_topology -profile $profile_file  -topology $topcons_fa -prediction modhmm -out $zpred_file -tmpdir $temp_dir\n";
	`$zpred -mode profile_topology -profile $profile_file  -topology $topcons_fa -prediction modhmm -out $zpred_file -tmpdir $temp_dir`;
#exit;
    }
    
    $mprap_file="$pdb.mpSA";
    if(-e $mprap_file) {
	if(-s $mprap_file==0) {
	    `rm $mprap_file`;
	}
	
    }
    if($overwrite || !-e $mprap_file) {
	@temp=split(/\//,$fasta);
	$outdir=join("/",@temp[0..$#temp-1]);
#print $outdir."\n";
	# print "scripts/run_MPSA.py $fasta $outdir/\n";
#exit;
	$outdir="." if(length($outdir)==0);
	print "MPRAP\n";
#    print "/home/bjornw/afs/.vol/bjornw27/MPSA/run_MPSA.py $fasta $outdir\n";
#	print "$INSTALL_DIR/bin/MPSA/run_MPSA.py $fasta $outdir\n";
	print "$INSTALL_DIR/apps/MPSA/run_MPSA.py $fasta $outdir $DB\n";
	`$INSTALL_DIR/apps/MPSA/run_MPSA.py $fasta $outdir $DB | egrep ' E|B ' > $mprap_file`;
	
    
    }
} else {
    $accfile="$pdb.acc";
    if($overwrite || !-e $accfile) {
	#pen(TEMP, ">$pdb.seq_file.tmp") || die "can't create temporary file.\n";
	#rint TEMP "1 20 3\n"; #create a title line required by ACCpro
	#rint TEMP "NONAME\n"; 
	#rint TEMP "$seq"; 
	#lose(TEMP);
	#`$INSTALL_DIR/apps/sspro4/script/process-blast.pl $pdb.fasta.blastpgp $pdb.msa_for_acc $pdb.fasta`;
	#print "$INSTALL_DIR/apps/sspro4/script/predict_seq_sa $INSTALL_DIR/apps/sspro4/model/accpro.model
	#
	#print "$INSTALL_DIR/apps/sspro4/script/homology_sa.pl $INSTALL_DIR/apps/sspro4/ $pdb.fasta $pdb.msa_for_acc $pdb.accpro\n";
	`$INSTALL_DIR/apps/sspro4/bin/predict_acc.sh $fasta $accfile.out`;
	`cat $accfile.out |tail -n 1 > $accfile`;

    }
}

sub parse_topcons
{
    my $file=shift;
    my $topcons="";
    my $seq="";
    my $octopus="";
    my $get_prediction=0;
    my %pred=();
    $pred{'TOPCONS'}="";
    open(FILE,$file);
    while(<FILE>)
    {
	chomp;
	
	if($get_sequence) {
	    if(length($_)==0) {
		$get_sequence=0;
	    } else {
		$seq.=$_;
	    }
	}
	if($get_prediction) {
	    if(length($_)==0) {
		$get_prediction=0;
	    } else {
		$pred{$method}.=$_;
	    }
	}
	if(/(.+)\spredicted topology:/) {
	    $method=$1;
	    $get_prediction=1;
	}
	$get_sequence=1 if(/Sequence:/);


    }
    close(FILE);
    $seq=~s/\s+//g;
 #   print $seq."\n";
    foreach $method(keys(%pred)) {
	$pred{$method}=~s/\s+//g;
#	print "$method\n$pred{$method}\n";
    }
    $pred{'TOPCONS'}=$pred{'OCTOPUS'} if(length($pred{'TOPCONS'})==0);
    if(length($topcons)==0) {
	$topcons=$seq;
	$topcons=~s/./i/g;
    }
   # "FILE $file\n";
    #print "SEQ     $seq\n";
    #print "TOPCONS $topcons\n";

    return($seq,$pred{'TOPCONS'});
}


