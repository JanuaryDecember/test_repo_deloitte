// Context files export both a provider component and a hook — fast-refresh limitation is expected.
/* eslint-disable react-refresh/only-export-components */
import { createContext, useCallback, useContext, useState } from 'react';
import type { ReactNode } from 'react';

interface MatchContextValue {
  matchCount: number;
  incrementMatchCount: () => void;
  setMatchCount: (n: number) => void;
}

const MatchContext = createContext<MatchContextValue>({
  matchCount: 0,
  incrementMatchCount: () => undefined,
  setMatchCount: () => undefined,
});

export function MatchProvider({ children }: { children: ReactNode }) {
  const [matchCount, setMatchCountState] = useState(0);

  const incrementMatchCount = useCallback(() => {
    setMatchCountState((n) => n + 1);
  }, []);

  const setMatchCount = useCallback((n: number) => {
    setMatchCountState(n);
  }, []);

  return (
    <MatchContext.Provider value={{ matchCount, incrementMatchCount, setMatchCount }}>
      {children}
    </MatchContext.Provider>
  );
}

export function useMatchCount() {
  return useContext(MatchContext);
}



