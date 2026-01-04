import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export function BookCardSkeleton() {
  return (
    <Card className="h-full overflow-hidden">
      <CardContent className="p-3 sm:p-4">
        <div className="flex gap-3 sm:gap-4">
          {/* Cover skeleton */}
          <Skeleton className="h-24 w-16 shrink-0 rounded sm:h-28 sm:w-[72px]" />

          {/* Content skeleton */}
          <div className="flex min-w-0 flex-1 flex-col">
            {/* Title */}
            <Skeleton className="mb-2 h-4 w-3/4" />
            <Skeleton className="mb-3 h-4 w-1/2" />

            {/* Author */}
            <Skeleton className="mb-auto h-3 w-1/3" />

            {/* Badge */}
            <Skeleton className="mt-2 h-5 w-16 rounded-full" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
