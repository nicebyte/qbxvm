macro qbx_insns m, [arg*] {
common
      m arg,    \
      noop,     \
      halt,     \
      moviwq0,  \
      moviwq1,  \
      moviwq2,  \
      moviwq3,  \
      movibq0,  \
      movibq1,  \
      movibq2,  \
      movibq3,  \
      movwq0q1, \
      movwq0q2, \
      movwq0q3, \
      movwq1q0, \
      movwq1q2, \
      movwq1q3, \
      movwq2q0, \
      movwq2q1, \
      movwq2q3, \
      movwq3q0, \
      movwq3q1, \
      movwq3q2, \
      movbq0q1, \
      movbq0q2, \
      movbq0q3, \
      movbq1q0, \
      movbq1q2, \
      movbq1q3, \
      movbq2q0, \
      movbq2q1, \
      movbq2q3, \
      movbq3q0, \
      movbq3q1, \
      movbq3q2, \
      storbdq0, \
      storbdq1, \
      storbdq2, \
      storbdq3, \
      storwdq0, \
      storwdq1, \
      storwdq2, \
      storwdq3, \
      storbiq1, \
      storbiq2, \
      storbiq3, \
      storwiq1, \
      storwiq2, \
      storwiq3, \
      loadbdq0, \
      loadbdq1, \
      loadbdq2, \
      loadbdq3, \
      loadwdq0, \
      loadwdq1, \
      loadwdq2, \
      loadwdq3, \
      loadbiq1, \
      loadbiq2, \
      loadbiq3, \
      loadwiq1, \
      loadwiq2, \
      loadwiq3, \
      pushbq0, \
      pushbq1, \
      pushbq2, \
      pushbq3, \
      pushwq0, \
      pushwq1, \
      pushwq2, \
      pushwq3, \
      popbq0, \
      popbq1, \
      popbq2, \
      popbq3, \
      popwq0, \
      popwq1, \
      popwq2, \
      popwq3, \
      addbq0q0, \
      addbq0q1, \
      addbq0q2, \
      addbq0q3, \
      addbq1q0, \
      addbq1q1, \
      addbq1q2, \
      addbq1q3, \
      addbq2q0, \
      addbq2q1, \
      addbq2q2, \
      addbq2q3, \
      addbq3q0, \
      addbq3q1, \
      addbq3q2, \
      addbq3q3, \
      addwq0q0, \
      addwq0q1, \
      addwq0q2, \
      addwq0q3, \
      addwq1q0, \
      addwq1q1, \
      addwq1q2, \
      addwq1q3, \
      addwq2q0, \
      addwq2q1, \
      addwq2q2, \
      addwq2q3, \
      addwq3q0, \
      addwq3q1, \
      addwq3q2, \
      addwq3q3, \
      subbq0q0, \
      subbq0q1, \
      subbq0q2, \
      subbq0q3, \
      subbq1q0, \
      subbq1q1, \
      subbq1q2, \
      subbq1q3, \
      subbq2q0, \
      subbq2q1, \
      subbq2q2, \
      subbq2q3, \
      subbq3q0, \
      subbq3q1, \
      subbq3q2, \
      subbq3q3, \
      subwq0q0, \
      subwq0q1, \
      subwq0q2, \
      subwq0q3, \
      subwq1q0, \
      subwq1q1, \
      subwq1q2, \
      subwq1q3, \
      subwq2q0, \
      subwq2q1, \
      subwq2q2, \
      subwq2q3, \
      subwq3q0, \
      subwq3q1, \
      subwq3q2, \
      subwq3q3, \
      mulbq2,   \
      mulbq3,   \
      mulwq2,   \
      mulwq3,   \
      smulbq2,  \
      smulbq3,  \
      smulwq2,  \
      smulwq3,  \
      divbq2,   \
      divbq3,   \
      divwq2,   \
      divwq3,   \
      sdivbq2,  \
      sdivbq3,  \
      sdivwq2,  \
      sdivwq3,  \
      andbq0q0, \
      andbq0q1, \
      andbq0q2, \
      andbq0q3, \
      andbq1q0, \
      andbq1q1, \
      andbq1q2, \
      andbq1q3, \
      andbq2q0, \
      andbq2q1, \
      andbq2q2, \
      andbq2q3, \
      andbq3q0, \
      andbq3q1, \
      andbq3q2, \
      andbq3q3, \
      andwq0q0, \
      andwq0q1, \
      andwq0q2, \
      andwq0q3, \
      andwq1q0, \
      andwq1q1, \
      andwq1q2, \
      andwq1q3, \
      andwq2q0, \
      andwq2q1, \
      andwq2q2, \
      andwq2q3, \
      andwq3q0, \
      andwq3q1, \
      andwq3q2, \
      andwq3q3, \
      orbq0q0,  \
      orbq0q1,  \
      orbq0q2,  \
      orbq0q3,  \
      orbq1q0,  \
      orbq1q1,  \
      orbq1q2,  \
      orbq1q3,  \
      orbq2q0,  \
      orbq2q1,  \
      orbq2q2,  \
      orbq2q3,  \
      orbq3q0,  \
      orbq3q1,  \
      orbq3q2,  \
      orbq3q3,  \
      orwq0q0,  \
      orwq0q1,  \
      orwq0q2,  \
      orwq0q3,  \
      orwq1q0,  \
      orwq1q1,  \
      orwq1q2,  \
      orwq1q3,  \
      orwq2q0,  \
      orwq2q1,  \
      orwq2q2,  \
      orwq2q3,  \
      orwq3q0,  \
      orwq3q1,  \
      orwq3q2,  \
      orwq3q3,  \
      notbq0,   \
      notbq1,   \
      notbq2,   \
      notbq3,   \
      notwq0,   \
      notwq1,   \
      notwq2,   \
      notwq3,   \
      xorbq0q0, \
      xorbq0q1, \
      xorbq0q2, \
      xorbq0q3, \
      xorbq1q0, \
      xorbq1q1, \
      xorbq1q2, \
      xorbq1q3, \
      xorbq2q0, \
      xorbq2q1, \
      xorbq2q2, \
      xorbq2q3, \
      xorbq3q0, \
      xorbq3q1, \
      xorbq3q2, \
      xorbq3q3, \
      xorwq0q0, \
      xorwq0q1, \
      xorwq0q2, \
      xorwq0q3, \
      xorwq1q0, \
      xorwq1q1, \
      xorwq1q2, \
      xorwq1q3, \
      xorwq2q0, \
      xorwq2q1, \
      xorwq2q2, \
      xorwq2q3, \
      xorwq3q0, \
      xorwq3q1, \
      xorwq3q2, \
      xorwq3q3, \
      jmpq0,    \
      jmpq1,    \
      jmpq2,    \
      jmpq3,    \
      jmpi,     \
      jzq0,     \
      jzq1,     \
      jzq2,     \
      jzq3,     \
      jnzq0,    \
      jnzq1,    \
      jnzq2,    \
      jznq3,    \
      jaq0,     \
      jaq1,     \
      jaq2,     \
      jaq3,     \
      jbq0,     \
      jbq1,     \
      jbq2,     \
      jbq3,     \
      jgq0,     \
      jgq1,     \
      jgq2,     \
      jgq3,     \
      jlq0,     \
      jlq1,     \
      jlq2,     \
      jlq3,     \
      callq0,   \
      callq1,   \
      callq2,   \
      callq3,   \
      return
}