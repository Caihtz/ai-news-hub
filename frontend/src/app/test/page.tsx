'use client';

import { useState, useEffect } from 'react';

export default function Test() {
  const [time, setTime] = useState('initial');

  useEffect(() => {
    const timer = setTimeout(() => setTime('after 2s'), 2000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div style={{padding: '50px', color: 'white', background: 'black'}}>
      <h1>Timer Test</h1>
      <p>Time state: {time}</p>
    </div>
  );
}