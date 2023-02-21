/////,
#include <iostream>
using namespace std;

void loop_via_ifstream(int istart, int iend)
{
  
  ifstream file_stream("file.list");
  string output_name = "nt"+std::to_string(istart)+"_"+std::to_string(iend)+".root";
  cout << output_name << endl;  

  TFile results("results.root", "recreate");
  TNtuple *b = new TNtuple("output_name", "Files & Numbers", "number");
  b->Print();

  string filename;
  int ifile = 0;
  while(true) {

    file_stream >> filename;

    if(file_stream.eof())
      break;

    if(ifile < istart) {
      ifile++;
      continue;
    }

    if(ifile >= iend)
      break;

    b->Fill(ifile);
    cout << "file  = " << ifile<<" name = "<<filename <<endl;

    //____ your analysis code
    //TFile fin(filename.c_str());

    //if(fin.IsZombie()) {
    //  ifile ++;   // you need this here to keep track of the file
    //  continue;
    //}

    ////TTree * tree = (TTree*)fin.Get("DecayTree");

    cout<<" output_name: "<<output_name<<endl;
    //fin.Close();
    //_____ end of your analysis code

    //
    ifile++;
  }
  results.cd();
  b->Write();
  results.Close();

}

