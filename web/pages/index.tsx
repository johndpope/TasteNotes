import { withPageAuth } from "@supabase/auth-helpers-nextjs";
import { Block, Card } from "konsta/react";
import { useEffect, useRef, useState } from "react";
import { API } from "../client";
import { FetchCheckInsResult } from "../client/check-ins";
import Layout from "../components/layout";
import { useInView } from "../utils/hooks";

export default function Activity() {
  return (
    <Layout title="Activity">
      <CheckInsFeed fetcher={API.checkIns.getActivityFeed} />
    </Layout>
  );
}

const CheckInsFeed = ({
  fetcher,
}: {
  fetcher: (page: number) => Promise<FetchCheckInsResult[]>;
}) => {
  const [checkIns, setCheckIns] = useState<FetchCheckInsResult[]>([]);
  const [page, setPage] = useState(1);
  const ref = useRef<HTMLDivElement | null>(null);
  const inView = useInView(ref);

  useEffect(() => {
    fetcher(page).then((d) => {
      setCheckIns(checkIns.concat(d));
      setPage((p) => p + 1);
    });
  }, [inView]);

  return (
    <Block
      style={{
        height: "100vh",
      }}
    >
      {checkIns.map((checkIn) => (
        <Card
          key={checkIn.id}
          header={
            <div className="-mx-4 -my-2 h-48 p-4 flex items-end  font-bold bg-cover bg-center">
              {checkIn.products["sub-brands"].brands.companies.name}{" "}
              {checkIn.products["sub-brands"].brands.name}{" "}
              {checkIn.products["sub-brands"].name ?? ""}{" "}
              {checkIn.products.name}
            </div>
          }
          footer={<div className="flex justify-between"></div>}
        >
          <div className="text-gray-500 mb-3">{checkIn.created_at}</div>
          <p>{checkIn.review}</p>
          <p>{checkIn.rating}</p>
        </Card>
      ))}
      <div ref={ref}>Loading...</div>
    </Block>
  );
};

export const getServerSideProps = withPageAuth({
  redirectTo: "/login",
});
