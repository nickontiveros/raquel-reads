'use client';

import { BookOpen } from 'lucide-react';
import { cn } from '@/lib/utils';

interface BookCoverProps {
  src?: string;
  alt: string;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizes = {
  sm: 'h-20 w-14',
  md: 'h-32 w-24',
  lg: 'h-48 w-36',
};

export function BookCover({ src, alt, size = 'md', className }: BookCoverProps) {
  if (!src) {
    return (
      <div
        className={cn(
          'flex items-center justify-center rounded-md bg-muted',
          sizes[size],
          className
        )}
      >
        <BookOpen className="h-1/3 w-1/3 text-muted-foreground" />
      </div>
    );
  }

  return (
    <div
      className={cn(
        'relative overflow-hidden rounded-md shadow-md',
        sizes[size],
        className
      )}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={src}
        alt={alt}
        className="h-full w-full object-cover"
        loading="lazy"
      />
    </div>
  );
}
