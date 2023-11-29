#include "iguana/Iguana.h"
#include <hipo4/reader.h>

void printParticles(std::string prefix, iguana::bank_ptr b) {
  std::vector<int> pids;
  for(int row=0; row<b->getRows(); row++)
    pids.push_back(b->get("pid", row));
  fmt::print("{}: {}\n", prefix, fmt::join(pids, ", "));
}

int main(int argc, char **argv) {

  // parse arguments
  int argi = 1;
  std::string inFileName = argc > argi ? std::string(argv[argi++]) : "data.hipo";
  int         numEvents  = argc > argi ? std::stoi(argv[argi++])   : 3;

  // start iguana
  /* TODO: will be similified when we have more sugar in `iguana::Iguana`; until then we
   * use the test algorithm directly
   */
  iguana::Iguana I;
  auto algo = I.algo_map.at(iguana::Iguana::clas12_EventBuilderFilter);
  algo->Log()->SetLevel("trace");
  // algo->Log()->DisableStyle();
  algo->SetOption("pids", std::set<int>{11, 211, -211});
  algo->SetOption("testInt", 3);
  algo->SetOption("testFloat", 11.0);
  algo->Start();

  /////////////////////////////////////////////////////

  // read input file
  hipo::reader reader;
  reader.open(inFileName.c_str());

  // get bank schema
  /* TODO: users should not have to do this; this is a workaround until
   * the pattern `hipo::event::getBank("REC::Particle")` is possible
   */
  hipo::dictionary factory;
  reader.readDictionary(factory);
  auto particleBank = std::make_shared<hipo::bank>(factory.getSchema("REC::Particle"));
  auto caloBank     = std::make_shared<hipo::bank>(factory.getSchema("REC::Calorimeter"));  // TODO: remove when not needed (this is for testing)

  // event loop
  hipo::event event;
  int iEvent = 0;
  while(reader.next(event) && (iEvent++ < numEvents || numEvents == 0)) {
    event.getStructure(*particleBank);
    printParticles("PIDS BEFORE algo->Run() ", particleBank);
    algo->Run({particleBank, caloBank});
    printParticles("PIDS AFTER algo->Run()  ", particleBank);
  }

  /////////////////////////////////////////////////////

  algo->Stop();
  return 0;
}
