'use client';

import { useState, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';

const USER_ID_KEY = 'raquel-reads-user-id';

export function useUserId(): string | null {
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    // Check if we already have a user ID
    let storedId = localStorage.getItem(USER_ID_KEY);

    if (!storedId) {
      // Generate a new user ID
      storedId = uuidv4();
      localStorage.setItem(USER_ID_KEY, storedId);
    }

    setUserId(storedId);
  }, []);

  return userId;
}

export function getUserId(): string {
  if (typeof window === 'undefined') {
    throw new Error('getUserId can only be called on the client');
  }

  let userId = localStorage.getItem(USER_ID_KEY);

  if (!userId) {
    userId = uuidv4();
    localStorage.setItem(USER_ID_KEY, userId);
  }

  return userId;
}
