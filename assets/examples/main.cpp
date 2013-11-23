#include <cstdio>
#include <cstdlib>
#include <string>

// [todo] - Find more Sherlock Holmes quotes
// [todo] - Write Watson response function 
// [todo] - Add debug mode with debug prints 

// [review] - Should I use char *argv[] or char **argv?
int main(int argc, char *argv[]){

  // [review] - Use namespace std to avoid std::String or not?
  std::String sherlock = "Elementary, my dear watson!\n";

  for (int i = 0; i < 10; i++){
    // [fix] - printf with %s and sherlock won't compile
    printf("%s\n", sherlock);
  }


}
