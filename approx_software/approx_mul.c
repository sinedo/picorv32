
/*

Copyright (C) 2025 Edonis Berisha, Jonas Moosbrugger, Nikola Szucsich

Licensed under the EUPL, Version 1.2 or – as soon they will be approved by
the European Commission - subsequent versions of the EUPL (the "Licence");
You may not use this work except in compliance with the Licence.
You may obtain a copy of the Licence at:

https://joinup.ec.europa.eu/software/page/eupl

Unless required by applicable law or agreed to in writing, software
distributed under the Licence is distributed on an "AS IS" basis,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the Licence for the specific language governing permissions and
limitations under the Licence.
*/

#include <stdint.h>

#define APPROX_MUL(a, b) ({                                \
/*
 * For Task 2
 * TODO: define the custom approx multiplication instruction
 */
int main () {
  // minor functionallity test, to see if the multiplier works
  // can be seen in testbench
  uint16_t result_approx;
  uint16_t result_exact;
  uint16_t a=3;
  for (uint16_t i = 0; i < 50; i++)
  {
    result_approx = APPROX_MUL(a,i);
    result_exact = a*i;
  }
  return 0;
}
