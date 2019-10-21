// /*** URL ***/

#include <cstdio>
#include <vector>
#include <string>

using namespace std;

#define DEBUG
#define REP(i,n)   for(int i=0; i<(int)(n); i++)
#define FOR(i,b,e) for(int i=(b); i<=(int)(e); i++)

//------------------------------------------------------------------------------
const int BUFSIZE = 1024;
char req[BUFSIZE];
char res[BUFSIZE];
#ifdef DEBUG
char source[BUFSIZE];
vector<string> responses;
#endif

void query() {
  printf("? %s\n", req);
  fflush(stdout);
#ifdef DEBUG
  sprintf(res, "generate response from source");
  responses.push_back(res);
#else
  scanf("%s", res);
#endif
}

//------------------------------------------------------------------------------
/*** CONSTS ***/

/*** DCLS ***/

void solve() {
  printf("! %s\n", ans);
  fflush(stdout);
#ifdef DEBUG
  printf("query count: %d\n", responses.size());
  puts("query results:");
  REP(i, responses.size()) {
    puts(responses[i].c_str());
  }
#endif
}

void input() {
  /*** INPUTS ***/
#ifdef DEBUG
  scanf("%s", source);
#endif
}

int main() {
  input();
  solve();
  return 0;
}
